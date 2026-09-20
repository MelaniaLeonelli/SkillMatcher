from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    status
)
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi.middleware.cors import CORSMiddleware

import secrets

from database import engine, get_db

from models import (
    Base,
    User,
    Team,
    TeamMembership,
    Skill,
    EmployeeSkill,
    Task,
    TaskSkill,
    Application,
    Rejection,
    Assignment
)

from schemas import (
    UserCreate,
    UserResponse,
    TeamCreate,
    TeamResponse,
    TeamMembershipResponse,
    JoinTeamRequest,
    SkillCreate,
    SkillResponse,
    EmployeeSkillCreate,
    EmployeeSkillResponse,
    TaskCreate,
    TaskResponse,
    TaskSkillCreate,
    TaskSkillResponse,
    ApplicationCreate,
    ApplicationResponse,
    RejectionCreate,
    RejectionResponse,
    AssignmentCreate,
    AssignmentResponse
)

from auth import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token
)


# =========================================================
# APP
# =========================================================

app = FastAPI(
    title="SkillMatcher API",
    description="Backend API per il progetto SkillMatcher",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =========================================================
# DATABASE
# =========================================================

Base.metadata.create_all(bind=engine)


# =========================================================
# AUTH CONFIGURATION
# =========================================================

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")


# =========================================================
# HELPER FUNCTIONS
# =========================================================

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token",
        headers={"WWW-Authenticate": "Bearer"}
    )

    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")

        if user_id is None:
            raise credentials_exception

        user_id = int(user_id)

    except Exception:
        raise credentials_exception

    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if user is None:
        raise credentials_exception

    return user


def get_membership(
    user_id: int,
    team_id: int,
    db: Session
):
    membership = (
        db.query(TeamMembership)
        .filter(
            TeamMembership.user_id == user_id,
            TeamMembership.team_id == team_id
        )
        .first()
    )

    return membership


def require_team_member(
    user_id: int,
    team_id: int,
    db: Session
):
    membership = get_membership(
        user_id=user_id,
        team_id=team_id,
        db=db
    )

    if membership is None:
        raise HTTPException(
            status_code=403,
            detail="User does not belong to this team"
        )

    return membership


def require_manager(
    user_id: int,
    team_id: int,
    db: Session
):
    membership = require_team_member(
        user_id=user_id,
        team_id=team_id,
        db=db
    )

    if membership.role != "manager":
        raise HTTPException(
            status_code=403,
            detail="Manager role required"
        )

    return membership


def require_employee(
    user_id: int,
    team_id: int,
    db: Session
):
    membership = require_team_member(
        user_id=user_id,
        team_id=team_id,
        db=db
    )

    if membership.role != "employee":
        raise HTTPException(
            status_code=403,
            detail="Employee role required"
        )

    return membership


# =========================================================
# ROOT / HEALTH
# =========================================================

@app.get("/")
def root():
    return {
        "message": "SkillMatcher backend running"
    }


@app.get("/health")
def health_check():
    return {
        "status": "ok"
    }


# =========================================================
# AUTHENTICATION
# =========================================================

@app.post("/register", response_model=UserResponse)
def register_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    existing_user = (
        db.query(User)
        .filter(User.email == user.email)
        .first()
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    new_user = User(
        name=user.name,
        email=user.email,
        password_hash=hash_password(user.password)
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user


@app.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = (
        db.query(User)
        .filter(User.email == form_data.username)
        .first()
    )

    if user is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    if not verify_password(
        form_data.password,
        user.password_hash
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    access_token = create_access_token(
        data={
            "sub": str(user.id)
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


@app.get("/me", response_model=UserResponse)
def get_me(
    current_user: User = Depends(get_current_user)
):
    return current_user


# =========================================================
# TEAMS
# =========================================================

@app.post("/teams", response_model=TeamResponse)
def create_team(
    team: TeamCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    invite_code = secrets.token_urlsafe(6)

    while (
        db.query(Team)
        .filter(Team.invite_code == invite_code)
        .first()
        is not None
    ):
        invite_code = secrets.token_urlsafe(6)

    new_team = Team(
        name=team.name,
        invite_code=invite_code
    )

    db.add(new_team)
    db.commit()
    db.refresh(new_team)

    membership = TeamMembership(
        user_id=current_user.id,
        team_id=new_team.id,
        role="manager"
    )

    db.add(membership)
    db.commit()

    return new_team


@app.post(
    "/teams/join",
    response_model=TeamMembershipResponse
)
def join_team(
    request: JoinTeamRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    team = (
        db.query(Team)
        .filter(Team.invite_code == request.invite_code)
        .first()
    )

    if team is None:
        raise HTTPException(
            status_code=404,
            detail="Invalid invite code"
        )

    existing_membership = (
        db.query(TeamMembership)
        .filter(
            TeamMembership.user_id == current_user.id,
            TeamMembership.team_id == team.id
        )
        .first()
    )

    if existing_membership is not None:
        raise HTTPException(
            status_code=400,
            detail="User already belongs to this team"
        )

    membership = TeamMembership(
        user_id=current_user.id,
        team_id=team.id,
        role="employee"
    )

    db.add(membership)
    db.commit()
    db.refresh(membership)

    return membership


@app.get("/teams")
def get_my_teams(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    memberships = (
        db.query(TeamMembership)
        .filter(
            TeamMembership.user_id == current_user.id
        )
        .all()
    )

    result = []

    for membership in memberships:
        team = (
            db.query(Team)
            .filter(Team.id == membership.team_id)
            .first()
        )

        if team is None:
            continue

        result.append({
            "team_id": team.id,
            "name": team.name,
            "invite_code": team.invite_code,
            "role": membership.role
        })

    return result


# =========================================================
# SKILLS
# =========================================================

@app.post("/skills", response_model=SkillResponse)
def create_skill(
    skill: SkillCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_team_member(
        current_user.id,
        skill.team_id,
        db
    )

    existing_skill = (
        db.query(Skill)
        .filter(
            Skill.team_id == skill.team_id,
            Skill.name == skill.name
        )
        .first()
    )

    if existing_skill is not None:
        raise HTTPException(
            status_code=400,
            detail="Skill already exists in this team"
        )

    new_skill = Skill(
        name=skill.name,
        team_id=skill.team_id
    )

    db.add(new_skill)
    db.commit()
    db.refresh(new_skill)

    return new_skill


@app.get(
    "/teams/{team_id}/skills",
    response_model=list[SkillResponse]
)
def get_team_skills(
    team_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_team_member(
        current_user.id,
        team_id,
        db
    )

    return (
        db.query(Skill)
        .filter(Skill.team_id == team_id)
        .all()
    )


# =========================================================
# EMPLOYEE SKILLS
# =========================================================

@app.post(
    "/employee-skills",
    response_model=EmployeeSkillResponse
)
def add_employee_skill(
    employee_skill: EmployeeSkillCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if employee_skill.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You can only modify your own skills"
        )

    skill = (
        db.query(Skill)
        .filter(Skill.id == employee_skill.skill_id)
        .first()
    )

    if skill is None:
        raise HTTPException(
            status_code=404,
            detail="Skill not found"
        )

    require_employee(
        current_user.id,
        skill.team_id,
        db
    )

    existing = (
        db.query(EmployeeSkill)
        .filter(
            EmployeeSkill.user_id == current_user.id,
            EmployeeSkill.skill_id == skill.id
        )
        .first()
    )

    if existing is not None:
        raise HTTPException(
            status_code=400,
            detail="Skill already associated with user"
        )

    new_employee_skill = EmployeeSkill(
        user_id=current_user.id,
        skill_id=skill.id,
        level=employee_skill.level
    )

    db.add(new_employee_skill)
    db.commit()
    db.refresh(new_employee_skill)

    return new_employee_skill


@app.get(
    "/me/skills",
    response_model=list[EmployeeSkillResponse]
)
def get_my_skills(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return (
        db.query(EmployeeSkill)
        .filter(
            EmployeeSkill.user_id == current_user.id
        )
        .all()
    )


@app.delete("/me/skills/{skill_id}")
def remove_my_skill(
    skill_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    skill = (
        db.query(Skill)
        .filter(Skill.id == skill_id)
        .first()
    )

    if skill is None:
        raise HTTPException(
            status_code=404,
            detail="Skill not found"
        )

    require_employee(
        current_user.id,
        skill.team_id,
        db
    )

    employee_skill = (
        db.query(EmployeeSkill)
        .filter(
            EmployeeSkill.user_id == current_user.id,
            EmployeeSkill.skill_id == skill_id
        )
        .first()
    )

    if employee_skill is None:
        raise HTTPException(
            status_code=404,
            detail="Skill is not associated with your profile"
        )

    db.delete(employee_skill)
    db.commit()

    return {
        "message": "Skill removed from profile successfully"
    }


# =========================================================
# TASKS
# =========================================================

@app.post("/tasks", response_model=TaskResponse)
def create_task(
    task: TaskCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    new_task = Task(
        title=task.title,
        description=task.description,
        priority=task.priority,
        deadline=task.deadline,
        created_by=current_user.id,
        team_id=task.team_id,
        status="open"
    )

    db.add(new_task)
    db.commit()
    db.refresh(new_task)

    return new_task


@app.get(
    "/teams/{team_id}/tasks",
    response_model=list[TaskResponse]
)
def get_team_tasks(
    team_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_team_member(
        current_user.id,
        team_id,
        db
    )

    return (
        db.query(Task)
        .filter(Task.team_id == team_id)
        .all()
    )


# =========================================================
# TEAM TASKS WITH REQUIRED SKILLS
# =========================================================

@app.get("/teams/{team_id}/tasks-with-skills")
def get_team_tasks_with_skills(
    team_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    require_team_member(
        current_user.id,
        team_id,
        db
    )

    tasks = (
        db.query(Task)
        .filter(Task.team_id == team_id)
        .all()
    )

    result = []

    for task in tasks:
        required_skills = (
            db.query(Skill)
            .join(
                TaskSkill,
                TaskSkill.skill_id == Skill.id
            )
            .filter(
                TaskSkill.task_id == task.id
            )
            .all()
        )

        result.append({
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "status": task.status,
            "priority": task.priority,
            "deadline": (
                task.deadline.isoformat()
                if task.deadline is not None
                else None
            ),
            "created_by": task.created_by,
            "team_id": task.team_id,
            "required_skills": [
                {
                    "id": skill.id,
                    "name": skill.name
                }
                for skill in required_skills
            ]
        })

    return result


@app.get("/tasks/{task_id}", response_model=TaskResponse)
def get_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_team_member(
        current_user.id,
        task.team_id,
        db
    )

    return task


# =========================================================
# UPDATE TASK
# =========================================================

@app.patch("/tasks/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    updated_task: TaskCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    if task.status != "open":
        raise HTTPException(
            status_code=400,
            detail="Only open tasks can be modified"
        )

    if updated_task.team_id != task.team_id:
        raise HTTPException(
            status_code=400,
            detail="Task cannot be moved to another team"
        )

    task.title = updated_task.title
    task.description = updated_task.description
    task.priority = updated_task.priority
    task.deadline = updated_task.deadline

    db.commit()
    db.refresh(task)

    return task


# =========================================================
# CLOSE TASK
# =========================================================

@app.patch("/tasks/{task_id}/close", response_model=TaskResponse)
def close_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    if task.status != "open":
        raise HTTPException(
            status_code=400,
            detail="Only open tasks can be closed"
        )

    task.status = "closed"

    db.commit()
    db.refresh(task)

    return task



# =========================================================
# TASK SKILLS
# =========================================================

@app.post(
    "/task-skills",
    response_model=TaskSkillResponse
)
def add_task_skill(
    task_skill: TaskSkillCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_skill.task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    skill = (
        db.query(Skill)
        .filter(Skill.id == task_skill.skill_id)
        .first()
    )

    if skill is None:
        raise HTTPException(
            status_code=404,
            detail="Skill not found"
        )

    if skill.team_id != task.team_id:
        raise HTTPException(
            status_code=400,
            detail="Skill and task must belong to the same team"
        )

    existing = (
        db.query(TaskSkill)
        .filter(
            TaskSkill.task_id == task.id,
            TaskSkill.skill_id == skill.id
        )
        .first()
    )

    if existing is not None:
        raise HTTPException(
            status_code=400,
            detail="Skill already associated with task"
        )

    new_task_skill = TaskSkill(
        task_id=task.id,
        skill_id=skill.id
    )

    db.add(new_task_skill)
    db.commit()
    db.refresh(new_task_skill)

    return new_task_skill


@app.get(
    "/tasks/{task_id}/skills",
    response_model=list[TaskSkillResponse]
)
def get_task_skills(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_team_member(
        current_user.id,
        task.team_id,
        db
    )

    return (
        db.query(TaskSkill)
        .filter(TaskSkill.task_id == task_id)
        .all()
    )

@app.put("/tasks/{task_id}/skills")
def update_task_skills(
    task_id: int,
    skill_ids: list[int],
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    if task.status != "open":
        raise HTTPException(
            status_code=400,
            detail="Only open tasks can be modified"
        )

    # Elimina le vecchie associazioni
    (
        db.query(TaskSkill)
        .filter(TaskSkill.task_id == task_id)
        .delete(
            synchronize_session=False
        )
    )

    # Evita eventuali ID duplicati
    unique_skill_ids = set(skill_ids)

    for skill_id in unique_skill_ids:

        # La skill deve esistere e appartenere
        # allo stesso team del task
        skill = (
            db.query(Skill)
            .filter(
                Skill.id == skill_id,
                Skill.team_id == task.team_id
            )
            .first()
        )

        if skill is None:
            db.rollback()

            raise HTTPException(
                status_code=400,
                detail=(
                    f"Skill {skill_id} not found "
                    "or does not belong to this team"
                )
            )

        db.add(
            TaskSkill(
                task_id=task_id,
                skill_id=skill_id
            )
        )

    db.commit()

    return {
        "message": "Task skills updated successfully",
        "task_id": task_id,
        "skill_ids": list(unique_skill_ids)
    }


# =========================================================
# RECOMMENDATIONS
# =========================================================

@app.get("/recommendations/{team_id}")
def get_recommendations(
    team_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Controlla che l'utente sia employee del team
    require_employee(
        current_user.id,
        team_id,
        db
    )

    # =====================================================
    # SKILL POSSEDUTE DALL'EMPLOYEE
    # =====================================================

    employee_skills = (
        db.query(EmployeeSkill)
        .join(
            Skill,
            EmployeeSkill.skill_id == Skill.id
        )
        .filter(
            EmployeeSkill.user_id == current_user.id,
            Skill.team_id == team_id
        )
        .all()
    )

    employee_skill_ids = {
        item.skill_id
        for item in employee_skills
    }

    # =====================================================
    # TASK GIÀ RIFIUTATI
    # =====================================================

    rejections = (
        db.query(Rejection)
        .join(
            Task,
            Rejection.task_id == Task.id
        )
        .filter(
            Rejection.employee_id == current_user.id,
            Task.team_id == team_id
        )
        .all()
    )

    rejected_task_ids = {
        item.task_id
        for item in rejections
    }

    # =====================================================
    # TASK AI QUALI SI È GIÀ CANDIDATO
    # =====================================================

    applications = (
        db.query(Application)
        .join(
            Task,
            Application.task_id == Task.id
        )
        .filter(
            Application.employee_id == current_user.id,
            Task.team_id == team_id
        )
        .all()
    )

    applied_task_ids = {
        item.task_id
        for item in applications
    }

    # =====================================================
    # TASK APERTI DEL TEAM
    # =====================================================

    tasks = (
        db.query(Task)
        .filter(
            Task.team_id == team_id,
            Task.status == "open"
        )
        .all()
    )

    recommendations = []

    # =====================================================
    # CALCOLO RECOMMENDATIONS
    # =====================================================

    for task in tasks:

        # Non mostra task già rifiutati
        if task.id in rejected_task_ids:
            continue

        # Non mostra task ai quali si è già candidato
        if task.id in applied_task_ids:
            continue

        # -------------------------------------------------
        # Skill richieste dal task
        # -------------------------------------------------

        task_skills = (
            db.query(TaskSkill)
            .filter(
                TaskSkill.task_id == task.id
            )
            .all()
        )

        task_skill_ids = {
            item.skill_id
            for item in task_skills
        }

        # Ignora task senza skill richieste
        if len(task_skill_ids) == 0:
            continue

        # -------------------------------------------------
        # Skill in comune
        # -------------------------------------------------

        matching_skill_ids = (
            employee_skill_ids
            .intersection(task_skill_ids)
        )

        # Per ora mostriamo solo task con almeno
        # una skill compatibile
        if len(matching_skill_ids) == 0:
            continue

        # -------------------------------------------------
        # Compatibilità
        # -------------------------------------------------

        compatibility = (
            len(matching_skill_ids)
            / len(task_skill_ids)
        ) * 100

        # -------------------------------------------------
        # Recupera i nomi delle skill
        # -------------------------------------------------

        required_skills = (
            db.query(Skill)
            .filter(
                Skill.id.in_(task_skill_ids)
            )
            .all()
        )

        skill_names = [
            skill.name
            for skill in required_skills
        ]

        # -------------------------------------------------
        # Recommendation completa
        # -------------------------------------------------

        recommendations.append({
            "task_id": task.id,
            "title": task.title,

            "description": task.description,

            "deadline": (
                task.deadline.isoformat()
                if task.deadline is not None
                else None
            ),

            "priority": task.priority,

            "compatibility": round(
                compatibility,
                2
            ),

            "skills": skill_names
        })

    # =====================================================
    # ORDINA PER COMPATIBILITÀ
    # =====================================================

    recommendations.sort(
        key=lambda item: item["compatibility"],
        reverse=True
    )

    return recommendations


# =========================================================
# APPLICATIONS
# =========================================================

@app.post(
    "/applications",
    response_model=ApplicationResponse
)
def create_application(
    application: ApplicationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if application.employee_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You can only apply as yourself"
        )

    task = (
        db.query(Task)
        .filter(Task.id == application.task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_employee(
        current_user.id,
        task.team_id,
        db
    )

    if task.status != "open":
        raise HTTPException(
            status_code=400,
            detail="Task is not available"
        )

    existing_application = (
        db.query(Application)
        .filter(
            Application.task_id == task.id,
            Application.employee_id == current_user.id
        )
        .first()
    )

    if existing_application is not None:
        raise HTTPException(
            status_code=400,
            detail="Application already exists"
        )

    existing_rejection = (
        db.query(Rejection)
        .filter(
            Rejection.task_id == task.id,
            Rejection.employee_id == current_user.id
        )
        .first()
    )

    if existing_rejection is not None:
        raise HTTPException(
            status_code=400,
            detail="Task already rejected"
        )

    new_application = Application(
        task_id=task.id,
        employee_id=current_user.id
    )

    db.add(new_application)
    db.commit()
    db.refresh(new_application)

    return new_application


# =========================================================
# REJECTIONS
# =========================================================

@app.post(
    "/rejections",
    response_model=RejectionResponse
)
def create_rejection(
    rejection: RejectionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if rejection.employee_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="You can only reject as yourself"
        )

    task = (
        db.query(Task)
        .filter(Task.id == rejection.task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_employee(
        current_user.id,
        task.team_id,
        db
    )

    if task.status != "open":
        raise HTTPException(
            status_code=400,
            detail="Task is not available"
        )

    existing_rejection = (
        db.query(Rejection)
        .filter(
            Rejection.task_id == task.id,
            Rejection.employee_id == current_user.id
        )
        .first()
    )

    if existing_rejection is not None:
        raise HTTPException(
            status_code=400,
            detail="Task already rejected"
        )

    existing_application = (
        db.query(Application)
        .filter(
            Application.task_id == task.id,
            Application.employee_id == current_user.id
        )
        .first()
    )

    if existing_application is not None:
        raise HTTPException(
            status_code=400,
            detail="Employee already applied to this task"
        )

    new_rejection = Rejection(
        task_id=task.id,
        employee_id=current_user.id
    )

    db.add(new_rejection)
    db.commit()
    db.refresh(new_rejection)

    return new_rejection


# =========================================================
# TASK APPLICATIONS
# =========================================================

@app.get(
    "/tasks/{task_id}/applications",
    response_model=list[ApplicationResponse]
)
def get_task_applications(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    return (
        db.query(Application)
        .filter(Application.task_id == task_id)
        .all()
    )


# =========================================================
# CANDIDATES
# =========================================================

@app.get("/tasks/{task_id}/candidates")
def get_task_candidates(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    task_skills = (
        db.query(TaskSkill)
        .filter(TaskSkill.task_id == task_id)
        .all()
    )

    task_skill_ids = {
        item.skill_id
        for item in task_skills
    }

    applications = (
        db.query(Application)
        .filter(Application.task_id == task_id)
        .all()
    )

    candidates = []

    for application in applications:

        employee = (
            db.query(User)
            .filter(
                User.id == application.employee_id
            )
            .first()
        )

        if employee is None:
            continue

        membership = get_membership(
            employee.id,
            task.team_id,
            db
        )

        if (
            membership is None
            or membership.role != "employee"
        ):
            continue

        employee_skills = (
            db.query(EmployeeSkill)
            .join(
                Skill,
                EmployeeSkill.skill_id == Skill.id
            )
            .filter(
                EmployeeSkill.user_id == employee.id,
                Skill.team_id == task.team_id
            )
            .all()
        )

        employee_skill_ids = {
            item.skill_id
            for item in employee_skills
        }

        matching_skill_ids = (
            employee_skill_ids
            .intersection(task_skill_ids)
        )

        if len(task_skill_ids) == 0:
            compatibility = 0
        else:
            compatibility = (
                len(matching_skill_ids)
                / len(task_skill_ids)
            ) * 100

        active_tasks = (
            db.query(Assignment)
            .join(
                Task,
                Assignment.task_id == Task.id
            )
            .filter(
                Assignment.employee_id == employee.id,
                Task.team_id == task.team_id,
                Task.status == "assigned"
            )
            .count()
        )

        candidates.append({
            "employee_id": employee.id,
            "name": employee.name,
            "compatibility": round(compatibility, 2),
            "active_tasks": active_tasks
        })

    candidates.sort(
        key=lambda candidate: candidate["compatibility"],
        reverse=True
    )

    return candidates


# =========================================================
# TASK EMPLOYEES
# =========================================================

@app.get("/tasks/{task_id}/employees")
def get_task_employees(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    task_skills = (
        db.query(TaskSkill)
        .filter(TaskSkill.task_id == task_id)
        .all()
    )

    task_skill_ids = {
        item.skill_id
        for item in task_skills
    }

    memberships = (
        db.query(TeamMembership)
        .filter(
            TeamMembership.team_id == task.team_id,
            TeamMembership.role == "employee"
        )
        .all()
    )

    employees = []

    for membership in memberships:
        employee = (
            db.query(User)
            .filter(User.id == membership.user_id)
            .first()
        )

        if employee is None:
            continue

        employee_skills = (
            db.query(EmployeeSkill)
            .join(
                Skill,
                EmployeeSkill.skill_id == Skill.id
            )
            .filter(
                EmployeeSkill.user_id == employee.id,
                Skill.team_id == task.team_id
            )
            .all()
        )

        employee_skill_ids = {
            item.skill_id
            for item in employee_skills
        }

        matching_skill_ids = (
            employee_skill_ids
            .intersection(task_skill_ids)
        )

        if len(task_skill_ids) == 0:
            compatibility = 0
        else:
            compatibility = (
                len(matching_skill_ids)
                / len(task_skill_ids)
            ) * 100

        active_tasks = (
            db.query(Assignment)
            .join(
                Task,
                Assignment.task_id == Task.id
            )
            .filter(
                Assignment.employee_id == employee.id,
                Task.team_id == task.team_id,
                Task.status == "assigned"
            )
            .count()
        )

        application = (
            db.query(Application)
            .filter(
                Application.task_id == task.id,
                Application.employee_id == employee.id
            )
            .first()
        )

        rejection = (
            db.query(Rejection)
            .filter(
                Rejection.task_id == task.id,
                Rejection.employee_id == employee.id
            )
            .first()
        )

        if application is not None:
            response_status = "applied"
        elif rejection is not None:
            response_status = "rejected"
        else:
            response_status = "none"

        employees.append({
            "employee_id": employee.id,
            "name": employee.name,
            "compatibility": round(compatibility, 2),
            "active_tasks": active_tasks,
            "response_status": response_status
        })

    employees.sort(
        key=lambda employee: (
            employee["response_status"] != "applied",
            -employee["compatibility"],
            employee["active_tasks"]
        )
    )

    return employees


# =========================================================
# ASSIGNMENTS
# =========================================================

@app.post(
    "/assignments",
    response_model=AssignmentResponse
)
def create_assignment(
    assignment: AssignmentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == assignment.task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    require_manager(
        current_user.id,
        task.team_id,
        db
    )

    if task.status != "open":
        raise HTTPException(
            status_code=400,
            detail="Task is not available"
        )

    employee = (
        db.query(User)
        .filter(User.id == assignment.employee_id)
        .first()
    )

    if employee is None:
        raise HTTPException(
            status_code=404,
            detail="Employee not found"
        )

    membership = get_membership(
        employee.id,
        task.team_id,
        db
    )

    if (
        membership is None
        or membership.role != "employee"
    ):
        raise HTTPException(
            status_code=400,
            detail="Employee does not belong to this team"
        )

    existing_assignment = (
        db.query(Assignment)
        .filter(Assignment.task_id == task.id)
        .first()
    )

    if existing_assignment is not None:
        raise HTTPException(
            status_code=400,
            detail="Task already assigned"
        )

    new_assignment = Assignment(
        task_id=task.id,
        employee_id=employee.id
    )

    db.add(new_assignment)

    task.status = "assigned"

    db.commit()
    db.refresh(new_assignment)

    return new_assignment


# =========================================================
# MY ASSIGNMENTS
# =========================================================

@app.get("/me/assignments")
def get_my_assignments(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    assignments = (
        db.query(Assignment)
        .filter(
            Assignment.employee_id == current_user.id
        )
        .all()
    )

    result = []

    for assignment in assignments:

        task = (
            db.query(Task)
            .filter(Task.id == assignment.task_id)
            .first()
        )

        if task is None:
            continue

        result.append({
            "assignment_id": assignment.id,
            "task_id": task.id,
            "team_id": task.team_id,
            "title": task.title,
            "status": task.status
        })

    return result


# =========================================================
# COMPLETE TASK
# =========================================================

@app.patch("/tasks/{task_id}/complete")
def complete_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = (
        db.query(Task)
        .filter(Task.id == task_id)
        .first()
    )

    if task is None:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    assignment = (
        db.query(Assignment)
        .filter(Assignment.task_id == task.id)
        .first()
    )

    if assignment is None:
        raise HTTPException(
            status_code=400,
            detail="Task is not assigned"
        )

    if assignment.employee_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Only the assigned employee can complete this task"
        )

    if task.status != "assigned":
        raise HTTPException(
            status_code=400,
            detail="Only assigned tasks can be completed"
        )

    task.status = "completed"

    db.commit()
    db.refresh(task)

    return {
        "message": "Task completed successfully",
        "task_id": task.id,
        "status": task.status
    }