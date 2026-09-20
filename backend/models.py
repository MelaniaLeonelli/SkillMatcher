from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    Date,
    UniqueConstraint
)

from database import Base


# =========================================================
# USER
# Account globale dell'utente.
# Il ruolo NON è più salvato qui.
# =========================================================

class User(Base):
    __tablename__ = "users"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    name = Column(
        String,
        nullable=False
    )

    email = Column(
        String,
        unique=True,
        nullable=False
    )

    password_hash = Column(
        String,
        nullable=False
    )


# =========================================================
# TEAM
# Rappresenta un'azienda / organizzazione.
# =========================================================

class Team(Base):
    __tablename__ = "teams"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    name = Column(
        String,
        nullable=False
    )

    invite_code = Column(
        String,
        unique=True,
        nullable=False
    )


# =========================================================
# TEAM MEMBERSHIP
# Collega un utente a un team e stabilisce il suo ruolo
# all'interno di quel team.
# =========================================================

class TeamMembership(Base):
    __tablename__ = "team_memberships"

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        primary_key=True
    )

    team_id = Column(
        Integer,
        ForeignKey("teams.id"),
        primary_key=True
    )

    role = Column(
        String,
        nullable=False
    )


# =========================================================
# SKILL
# Catalogo delle skill di uno specifico team.
# =========================================================

class Skill(Base):
    __tablename__ = "skills"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    name = Column(
        String,
        nullable=False
    )

    team_id = Column(
        Integer,
        ForeignKey("teams.id"),
        nullable=False
    )

    # La stessa skill non può essere duplicata
    # nello stesso team.
    __table_args__ = (
        UniqueConstraint(
            "team_id",
            "name",
            name="uq_team_skill"
        ),
    )


# =========================================================
# EMPLOYEE SKILL
# Skill posseduta da un utente all'interno di un team.
# =========================================================

class EmployeeSkill(Base):
    __tablename__ = "employee_skills"

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        primary_key=True
    )

    skill_id = Column(
        Integer,
        ForeignKey("skills.id"),
        primary_key=True
    )

    level = Column(
        Integer,
        nullable=True
    )


# =========================================================
# TASK
# Ogni task appartiene obbligatoriamente a un team.
# =========================================================

class Task(Base):
    __tablename__ = "tasks"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    title = Column(
        String,
        nullable=False
    )

    description = Column(
        String,
        nullable=True
    )

    status = Column(
        String,
        default="open",
        nullable=False
    )

    priority = Column(
        String,
        nullable=True
    )

    deadline = Column(
        Date,
        nullable=True
    )

    created_by = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    team_id = Column(
        Integer,
        ForeignKey("teams.id"),
        nullable=False
    )


# =========================================================
# TASK SKILL
# Skill richiesta da un task.
# =========================================================

class TaskSkill(Base):
    __tablename__ = "task_skills"

    task_id = Column(
        Integer,
        ForeignKey("tasks.id"),
        primary_key=True
    )

    skill_id = Column(
        Integer,
        ForeignKey("skills.id"),
        primary_key=True
    )


# =========================================================
# APPLICATION
# Candidatura di un dipendente a un task.
# =========================================================

class Application(Base):
    __tablename__ = "applications"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    task_id = Column(
        Integer,
        ForeignKey("tasks.id"),
        nullable=False
    )

    employee_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    __table_args__ = (
        UniqueConstraint(
            "task_id",
            "employee_id",
            name="uq_task_application"
        ),
    )


# =========================================================
# REJECTION
# Task rifiutato da un dipendente.
# =========================================================

class Rejection(Base):
    __tablename__ = "rejections"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    task_id = Column(
        Integer,
        ForeignKey("tasks.id"),
        nullable=False
    )

    employee_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    __table_args__ = (
        UniqueConstraint(
            "task_id",
            "employee_id",
            name="uq_task_rejection"
        ),
    )


# =========================================================
# ASSIGNMENT
# Assegnazione definitiva di un task a un dipendente.
# =========================================================

class Assignment(Base):
    __tablename__ = "assignments"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    task_id = Column(
        Integer,
        ForeignKey("tasks.id"),
        nullable=False,
        unique=True
    )

    employee_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )