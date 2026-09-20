import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.28:8000';

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Utente non autenticato');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final token = data['access_token'] as String;

      await saveToken(token);

      return token;
    }

    if (response.statusCode == 401) {
      throw Exception('Email o password non corretti');
    }

    throw Exception(
      'Errore durante il login (${response.statusCode})',
    );
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final headers = await getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw Exception('Sessione scaduta');
    }

    throw Exception(
      'Errore durante il recupero dell\'utente '
      '(${response.statusCode})',
    );
  }

  // ============================================================
  // MY TEAMS
  // ============================================================

  static Future<List<dynamic>> getMyTeams() async {
    final headers = await getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/teams'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw Exception('Sessione scaduta');
    }

    throw Exception(
      'Errore durante il recupero dei team '
      '(${response.statusCode})',
    );
  }

  // ============================================================
  // RECOMMENDATIONS
  // ============================================================

  static Future<List<dynamic>> getRecommendations(
    int teamId,
  ) async {
    final headers = await getAuthHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/recommendations/$teamId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      throw Exception('Sessione scaduta');
    }

    if (response.statusCode == 403) {
      throw Exception(
        'Non hai accesso alle raccomandazioni di questo team',
      );
    }

    throw Exception(
      'Errore durante il recupero delle raccomandazioni '
      '(${response.statusCode})',
    );
  }

  // ============================================================
  // APPLICATION
  // ============================================================

  static Future<void> applyToTask({
    required int taskId,
    required int employeeId,
  }) async {
    final headers = await getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/applications'),
      headers: headers,
      body: jsonEncode({
        'task_id': taskId,
        'employee_id': employeeId,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 400) {
      final data = jsonDecode(response.body);

      throw Exception(
        data['detail'] ?? 'Impossibile candidarsi al task',
      );
    }

    if (response.statusCode == 401) {
      throw Exception('Sessione scaduta');
    }

    if (response.statusCode == 403) {
      throw Exception('Operazione non autorizzata');
    }

    throw Exception(
      'Errore durante la candidatura '
      '(${response.statusCode})',
    );
  }

  // ============================================================
  // REJECTION
  // ============================================================

  static Future<void> rejectTask({
    required int taskId,
    required int employeeId,
  }) async {
    final headers = await getAuthHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/rejections'),
      headers: headers,
      body: jsonEncode({
        'task_id': taskId,
        'employee_id': employeeId,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 400) {
      final data = jsonDecode(response.body);

      throw Exception(
        data['detail'] ?? 'Impossibile rifiutare il task',
      );
    }

    if (response.statusCode == 401) {
      throw Exception('Sessione scaduta');
    }

    if (response.statusCode == 403) {
      throw Exception('Operazione non autorizzata');
    }

    throw Exception(
      'Errore durante il rifiuto '
      '(${response.statusCode})',
    );
  }

  // ============================================================
// MY SKILLS
// GET /me/skills
// ============================================================

static Future<List<dynamic>> getMySkills() async {
  final headers = await getAuthHeaders();

  final response = await http.get(
    Uri.parse('$baseUrl/me/skills'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  throw Exception(
    'Errore durante il recupero delle skill '
    '(${response.statusCode})',
  );
}

// ============================================================
// TEAM SKILLS
// GET /teams/{team_id}/skills
// ============================================================

static Future<List<dynamic>> getTeamSkills(
  int teamId,
) async {
  final headers = await getAuthHeaders();

  final response = await http.get(
    Uri.parse('$baseUrl/teams/$teamId/skills'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Non hai accesso alle skill di questo team',
    );
  }

  throw Exception(
    'Errore durante il recupero delle skill '
    '(${response.statusCode})',
  );
}

// ============================================================
// ADD EMPLOYEE SKILL
// POST /employee-skills
// ============================================================

static Future<void> addEmployeeSkill({
  required int userId,
  required int skillId,
  required int level,
}) async {
  final headers = await getAuthHeaders();

  final response = await http.post(
    Uri.parse('$baseUrl/employee-skills'),
    headers: headers,
    body: jsonEncode({
      'user_id': userId,
      'skill_id': skillId,
      'level': level,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  final data = jsonDecode(response.body);

  throw Exception(
    data['detail'] ??
        'Errore durante l\'aggiunta della skill',
  );
}

// ============================================================
// MY ASSIGNMENTS
// GET /me/assignments
// ============================================================

static Future<List<dynamic>> getMyAssignments() async {
  final headers = await getAuthHeaders();

  final response = await http.get(
    Uri.parse('$baseUrl/me/assignments'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  throw Exception(
    'Errore durante il recupero dei task assegnati '
    '(${response.statusCode})',
  );
}

// ============================================================
// COMPLETE TASK
// PATCH /tasks/{task_id}/complete
// ============================================================

static Future<void> completeTask(
  int taskId,
) async {
  final headers = await getAuthHeaders();

  final response = await http.patch(
    Uri.parse('$baseUrl/tasks/$taskId/complete'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return;
  }

  final data = jsonDecode(response.body);

  throw Exception(
    data['detail'] ??
        'Errore durante il completamento del task',
  );
}
// ============================================================
// CREATE TASK
// POST /tasks
// ============================================================

static Future<Map<String, dynamic>> createTask({
  required String title,
  required String description,
  required String priority,
  required String deadline,
  required int teamId,
}) async {
  final headers = await getAuthHeaders();

  final response = await http.post(
    Uri.parse('$baseUrl/tasks'),
    headers: headers,
    body: jsonEncode({
      'title': title,
      'description': description,
      'priority': priority,
      'deadline': deadline,
      'team_id': teamId,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  final data = jsonDecode(response.body);

  throw Exception(
    data['detail'] ??
        'Errore durante la creazione del task',
  );
}


// ============================================================
// CREATE SKILL
// POST /skills
// ============================================================

static Future<Map<String, dynamic>> createSkill({
  required String name,
  required int teamId,
}) async {
  final headers = await getAuthHeaders();

  final response = await http.post(
    Uri.parse('$baseUrl/skills'),
    headers: headers,
    body: jsonEncode({
      'name': name,
      'team_id': teamId,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  final data = jsonDecode(response.body);

  throw Exception(
    data['detail'] ??
        'Errore durante la creazione della skill',
  );
}



// ============================================================
// GET TASK SKILLS
// GET /tasks/{task_id}/skills
// ============================================================

static Future<List<dynamic>> getTaskSkills(
  int taskId,
) async {
  final headers = await getAuthHeaders();

  final response = await http.get(
    Uri.parse(
      '$baseUrl/tasks/$taskId/skills',
    ),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) {
      return data;
    }

    return [];
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Non sei autorizzato a visualizzare le skill del task',
    );
  }

  if (response.statusCode == 404) {
    throw Exception('Task non trovato');
  }

  throw Exception(
    'Errore durante il recupero delle skill del task '
    '(${response.statusCode})',
  );
}

// ============================================================
// ADD TASK SKILL
// POST /task-skills
// ============================================================

static Future<void> updateTaskSkills({
  required int taskId,
  required List<int> skillIds,
}) async {
  final headers = await getAuthHeaders();

  final response = await http.put(
    Uri.parse(
      '$baseUrl/tasks/$taskId/skills',
    ),
    headers: headers,
    body: jsonEncode(
      skillIds,
    ),
  );

  if (response.statusCode == 200) {
    return;
  }

  if (response.statusCode == 400) {
    final data =
        jsonDecode(response.body);

    throw Exception(
      data['detail'] ??
          'Impossibile modificare le skill del task',
    );
  }

  if (response.statusCode == 401) {
    throw Exception(
      'Sessione scaduta',
    );
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Non sei autorizzato a modificare le skill del task',
    );
  }

  if (response.statusCode == 404) {
    throw Exception(
      'Task non trovato',
    );
  }

  throw Exception(
    'Errore durante la modifica delle skill '
    '(${response.statusCode})',
  );
}

static Future<void> addTaskSkill({
  required int taskId,
  required int skillId,
}) async {
  final headers = await getAuthHeaders();

  final response = await http.post(
    Uri.parse('$baseUrl/task-skills'),
    headers: headers,
    body: jsonEncode({
      'task_id': taskId,
      'skill_id': skillId,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  final data = jsonDecode(response.body);

  throw Exception(
    data['detail'] ??
        'Errore durante l\'associazione della skill',
  );
}
// ============================================================
// TEAM TASKS
// GET /teams/{team_id}/tasks
// ============================================================

static Future<List<dynamic>> getTeamTasks(
  int teamId,
) async {
  final headers =
      await getAuthHeaders();

  final response =
      await http.get(
    Uri.parse(
      '$baseUrl/teams/$teamId/tasks',
    ),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(
      response.body,
    );
  }

  throw Exception(
    'Errore durante il recupero dei task '
    '(${response.statusCode})',
  );
}



// ============================================================
// TEAM TASKS WITH SKILLS
// GET /teams/{team_id}/tasks-with-skills
// ============================================================

static Future<List<dynamic>> getTeamTasksWithSkills(
  int teamId,
) async {
  final headers = await getAuthHeaders();

  final response = await http.get(
    Uri.parse(
      '$baseUrl/teams/$teamId/tasks-with-skills',
    ),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) {
      return data;
    }

    return [];
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Non sei autorizzato a visualizzare i task del team',
    );
  }

  throw Exception(
    'Errore durante il recupero dei task con skill '
    '(${response.statusCode})',
  );
}

// ============================================================
// TASK CANDIDATES
// GET /tasks/{task_id}/candidates
// ============================================================

static Future<List<dynamic>>
    getTaskCandidates(
  int taskId,
) async {
  final headers =
      await getAuthHeaders();

  final response =
      await http.get(
    Uri.parse(
      '$baseUrl/tasks/$taskId/candidates',
    ),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(
      response.body,
    );
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Solo il manager può visualizzare i candidati',
    );
  }

  throw Exception(
    'Errore durante il recupero dei candidati '
    '(${response.statusCode})',
  );
}


// ============================================================
// ASSIGN TASK
// POST /assignments
// ============================================================

static Future<void> assignTask({
  required int taskId,
  required int employeeId,
}) async {
  final headers =
      await getAuthHeaders();

  final response =
      await http.post(
    Uri.parse(
      '$baseUrl/assignments',
    ),
    headers: headers,
    body: jsonEncode({
      'task_id': taskId,
      'employee_id':
          employeeId,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  try {
    final data =
        jsonDecode(
      response.body,
    );

    throw Exception(
      data['detail'] ??
          'Errore durante l\'assegnazione',
    );
  } catch (_) {
    throw Exception(
      'Errore durante l\'assegnazione '
      '(${response.statusCode})',
    );
  }
}

// ============================================================
// REMOVE MY SKILL
// DELETE /me/skills/{skill_id}
// ============================================================

static Future<void> removeMySkill(
  int skillId,
) async {
  final headers = await getAuthHeaders();

  final response = await http.delete(
    Uri.parse(
      '$baseUrl/me/skills/$skillId',
    ),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return;
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Non puoi rimuovere questa skill',
    );
  }

  if (response.statusCode == 404) {
    throw Exception(
      'Skill non associata al tuo profilo',
    );
  }

  throw Exception(
    'Errore durante la rimozione della skill '
    '(${response.statusCode})',
  );
}
// ============================================================
// GET ALL EMPLOYEES FOR A TASK
// Manager: candidati + non candidati + rifiutati
// ============================================================

static Future<List<dynamic>> getTaskEmployees(
  int taskId,
) async {
  final headers = await getAuthHeaders();

  final response = await http.get(
    Uri.parse(
      '$baseUrl/tasks/$taskId/employees',
    ),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) {
      return data;
    }

    return [];
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Non sei autorizzato a visualizzare i dipendenti di questo task',
    );
  }

  if (response.statusCode == 404) {
    throw Exception('Task non trovato');
  }

  throw Exception(
    'Errore durante il caricamento dei dipendenti '
    '(${response.statusCode})',
  );
}

// ============================================================
// REGISTER
// ============================================================

static Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/register'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'name': name,
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200 ||
      response.statusCode == 201) {
    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  if (response.statusCode == 400) {
    try {
      final data = jsonDecode(response.body);

      throw Exception(
        data['detail'] ??
            'Impossibile completare la registrazione',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Impossibile completare la registrazione',
      );
    }
  }

  if (response.statusCode == 422) {
    throw Exception(
      'Controlla i dati inseriti',
    );
  }

  throw Exception(
    'Errore durante la registrazione '
    '(${response.statusCode})',
  );
}

// ============================================================
// CREATE TEAM
// ============================================================

static Future<Map<String, dynamic>> createTeam({
  required String name,
}) async {
  final headers = await getAuthHeaders();

  final response = await http.post(
    Uri.parse('$baseUrl/teams'),
    headers: headers,
    body: jsonEncode({
      'name': name,
    }),
  );

  if (response.statusCode == 200 ||
      response.statusCode == 201) {
    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  try {
    final data = jsonDecode(response.body);

    throw Exception(
      data['detail'] ??
          'Errore durante la creazione del team',
    );
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception(
      'Errore durante la creazione del team '
      '(${response.statusCode})',
    );
  }
}

// ============================================================
// JOIN TEAM
// ============================================================

static Future<Map<String, dynamic>> joinTeam({
  required String inviteCode,
}) async {
  final headers = await getAuthHeaders();

  final response = await http.post(
    Uri.parse('$baseUrl/teams/join'),
    headers: headers,
    body: jsonEncode({
      'invite_code': inviteCode,
    }),
  );

  if (response.statusCode == 200 ||
      response.statusCode == 201) {
    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  if (response.statusCode == 404) {
    throw Exception(
      'Codice di invito non valido',
    );
  }

  if (response.statusCode == 400) {
    throw Exception(
      'Fai già parte di questo team',
    );
  }

  try {
    final data = jsonDecode(response.body);

    throw Exception(
      data['detail'] ??
          'Errore durante l’ingresso nel team',
    );
  } catch (e) {
    if (e is Exception) {
      rethrow;
    }

    throw Exception(
      'Errore durante l’ingresso nel team '
      '(${response.statusCode})',
    );
  }
}

// ============================================================
// UPDATE TASK
// PATCH /tasks/{task_id}
// ============================================================

static Future<Map<String, dynamic>> updateTask({
  required int taskId,
  required String title,
  required String description,
  required String priority,
  required String? deadline,
  required int teamId,
}) async {
  final headers = await getAuthHeaders();

  final response = await http.patch(
    Uri.parse('$baseUrl/tasks/$taskId'),
    headers: headers,
    body: jsonEncode({
      'title': title,
      'description': description,
      'priority': priority,
      'deadline': deadline,
      'team_id': teamId,
    }),
  );

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  if (response.statusCode == 400) {
    final data = jsonDecode(response.body);

    throw Exception(
      data['detail'] ??
          'Impossibile modificare il task',
    );
  }

  if (response.statusCode == 401) {
    throw Exception('Sessione scaduta');
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Non sei autorizzato a modificare questo task',
    );
  }

  if (response.statusCode == 404) {
    throw Exception(
      'Task non trovato',
    );
  }

  throw Exception(
    'Errore durante la modifica del task '
    '(${response.statusCode})',
  );
}

// ============================================================
// CLOSE TASK
// PATCH /tasks/{task_id}/close
// ============================================================

static Future<Map<String, dynamic>> closeTask(
  int taskId,
) async {
  final headers = await getAuthHeaders();

  final response = await http.patch(
    Uri.parse(
      '$baseUrl/tasks/$taskId/close',
    ),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  if (response.statusCode == 400) {
    final data = jsonDecode(response.body);

    throw Exception(
      data['detail'] ??
          'Impossibile chiudere il task',
    );
  }

  if (response.statusCode == 401) {
    throw Exception(
      'Sessione scaduta',
    );
  }

  if (response.statusCode == 403) {
    throw Exception(
      'Non sei autorizzato a chiudere questo task',
    );
  }

  if (response.statusCode == 404) {
    throw Exception(
      'Task non trovato',
    );
  }

  throw Exception(
    'Errore durante la chiusura del task '
    '(${response.statusCode})',
  );
}


}