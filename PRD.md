# ROLE SYSTEM

The application only has 3 main roles:

1. Admin / Guru BK / Kepala Sekolah
2. Wali Kelas
3. Siswa

IMPORTANT:

- Admin, Guru BK, and Kepala Sekolah share the SAME dashboard and permission scope.
- Do NOT separate Admin and Guru BK into different role systems.
- Treat them as one unified management role.

---

# ROLE STRUCTURE

## ROLE 1

role: "admin"

Includes:

- Admin BK
- Guru BK
- Kepala Sekolah

Access:

- Full monitoring dashboard
- Input poin siswa
- Counseling management
- Surat panggilan
- Reports
- Student management

Main Screens:

- Administration Overview
- Counselor Workspace
- Input Point
- Student Department
- Summons Generator

---

## ROLE 2

role: "wali_kelas"

Access:

- Monitoring siswa kelas
- View student wellbeing
- Student alerts
- Counseling monitoring

Main Screens:

- Wali Kelas Dashboard
- Monitoring Records
- Student Detail Monitoring

---

## ROLE 3

role: "student"

Access:

- Student dashboard
- Counseling chat
- Submit report
- View summons
- Safety score

Main Screens:

- Student Dashboard
- Counseling Chat
- Submit Incident Report
- Inbox
- Appointment

---

# IMPORTANT IMPLEMENTATION RULE

DO NOT create:

- separate guru_bk role
- separate kepala_sekolah role

Everything management-related must use:
role = "admin"

Only 3 roles exist in the application.
