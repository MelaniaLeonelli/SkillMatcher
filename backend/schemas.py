from datetime import date
from pydantic import BaseModel, ConfigDict


# =========================================================
# USER
# =========================================================

class UserCreate(BaseModel):
    name: str
    email: str
    password: str


class UserResponse(BaseModel):
    id: int
    name: str
    email: str

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# TEAM
# =========================================================

class TeamCreate(BaseModel):
    name: str


class TeamResponse(BaseModel):
    id: int
    name: str
    invite_code: str

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# TEAM MEMBERSHIP
# =========================================================

class TeamMembershipCreate(BaseModel):
    user_id: int
    team_id: int
    role: str


class TeamMembershipResponse(BaseModel):
    user_id: int
    team_id: int
    role: str

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# JOIN TEAM
# Utilizzato quando un utente entra in un team
# tramite codice di invito.
# =========================================================

class JoinTeamRequest(BaseModel):
    invite_code: str


# =========================================================
# SKILL
# =========================================================

class SkillCreate(BaseModel):
    name: str
    team_id: int


class SkillResponse(BaseModel):
    id: int
    name: str
    team_id: int

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# EMPLOYEE SKILL
# =========================================================

class EmployeeSkillCreate(BaseModel):
    user_id: int
    skill_id: int
    level: int | None = None


class EmployeeSkillResponse(BaseModel):
    user_id: int
    skill_id: int
    level: int | None = None

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# TASK
# =========================================================

class TaskCreate(BaseModel):
    title: str
    description: str | None = None
    priority: str | None = None
    deadline: date | None = None
    team_id: int


class TaskResponse(BaseModel):
    id: int
    title: str
    description: str | None = None
    status: str
    priority: str | None = None
    deadline: date | None = None
    created_by: int
    team_id: int

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# TASK SKILL
# =========================================================

class TaskSkillCreate(BaseModel):
    task_id: int
    skill_id: int


class TaskSkillResponse(BaseModel):
    task_id: int
    skill_id: int

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# APPLICATION
# =========================================================

class ApplicationCreate(BaseModel):
    task_id: int
    employee_id: int


class ApplicationResponse(BaseModel):
    id: int
    task_id: int
    employee_id: int

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# REJECTION
# =========================================================

class RejectionCreate(BaseModel):
    task_id: int
    employee_id: int


class RejectionResponse(BaseModel):
    id: int
    task_id: int
    employee_id: int

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# ASSIGNMENT
# =========================================================

class AssignmentCreate(BaseModel):
    task_id: int
    employee_id: int


class AssignmentResponse(BaseModel):
    id: int
    task_id: int
    employee_id: int

    model_config = ConfigDict(from_attributes=True)