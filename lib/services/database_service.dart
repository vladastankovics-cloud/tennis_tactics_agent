import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tennis_tactics.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 29,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create matches table
    await db.execute('''
      CREATE TABLE matches (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        opponent_name TEXT NOT NULL,
        opponent_name_2 TEXT,
        partner_name TEXT,
        match_date INTEGER,
        match_result TEXT,
        match_score_user INTEGER,
        match_score_opponent INTEGER,
        set_scores TEXT,
        match_type TEXT,
        match_format TEXT,
        no_ads INTEGER DEFAULT 0,
        tiebreak_set INTEGER DEFAULT 0,
        court_name TEXT,
        court_surface TEXT,
        court_speed TEXT,
        court_cover TEXT,
        court_conditions TEXT,
        altitude TEXT,
        my_adjustment TEXT,
        opponent_adjustment TEXT,
        balls TEXT,
        crowd TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_synced INTEGER
      )
    ''');

    // Create conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        match_id TEXT,
        title TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_synced INTEGER,
        FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE SET NULL
      )
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_error INTEGER DEFAULT 0,
        last_synced INTEGER,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    // Create opponents table
    await db.execute('''
      CREATE TABLE opponents (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        agility INTEGER DEFAULT 50,
        mobility INTEGER DEFAULT 50,
        lean_body INTEGER DEFAULT 50,
        endurance INTEGER DEFAULT 50,
        power INTEGER DEFAULT 50,
        reach INTEGER DEFAULT 50,
        coordination INTEGER DEFAULT 50,
        balance INTEGER DEFAULT 50,
        serve INTEGER DEFAULT 50,
        return_serve INTEGER DEFAULT 50,
        forehand INTEGER DEFAULT 50,
        backhand INTEGER DEFAULT 50,
        transition INTEGER DEFAULT 50,
        net INTEGER DEFAULT 50,
        specialty INTEGER DEFAULT 50,
        counterpuncher INTEGER DEFAULT 50,
        aggressive_baseliner INTEGER DEFAULT 50,
        all_court_player INTEGER DEFAULT 50,
        net_rusher INTEGER DEFAULT 50,
        serve_and_volleyer INTEGER DEFAULT 50,
        big_server INTEGER DEFAULT 50,
        family INTEGER DEFAULT 50,
        coaches INTEGER DEFAULT 50,
        partners INTEGER DEFAULT 50,
        crowd INTEGER DEFAULT 50,
        sponsors INTEGER DEFAULT 50,
        focus INTEGER DEFAULT 50,
        calmness INTEGER DEFAULT 50,
        clutchness INTEGER DEFAULT 50,
        confidence INTEGER DEFAULT 50,
        birth_year INTEGER,
        height_cm INTEGER,
        weight_kg REAL,
        active_since_year TEXT,
        hands TEXT,
        backhand_type TEXT,
        level TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create user_profile table (single row for the user)
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        birth_year INTEGER,
        height_cm INTEGER,
        weight_kg REAL,
        active_since_year TEXT,
        hands TEXT,
        backhand_type TEXT,
        level TEXT,
        agility INTEGER DEFAULT 50,
        mobility INTEGER DEFAULT 50,
        lean_body INTEGER DEFAULT 50,
        endurance INTEGER DEFAULT 50,
        power INTEGER DEFAULT 50,
        reach INTEGER DEFAULT 50,
        coordination INTEGER DEFAULT 50,
        balance INTEGER DEFAULT 50,
        serve INTEGER DEFAULT 50,
        return_serve INTEGER DEFAULT 50,
        forehand INTEGER DEFAULT 50,
        backhand INTEGER DEFAULT 50,
        transition INTEGER DEFAULT 50,
        net INTEGER DEFAULT 50,
        specialty INTEGER DEFAULT 50,
        counterpuncher INTEGER DEFAULT 50,
        aggressive_baseliner INTEGER DEFAULT 50,
        all_court_player INTEGER DEFAULT 50,
        net_rusher INTEGER DEFAULT 50,
        serve_and_volleyer INTEGER DEFAULT 50,
        big_server INTEGER DEFAULT 50,
        family INTEGER DEFAULT 50,
        coaches INTEGER DEFAULT 50,
        partners INTEGER DEFAULT 50,
        crowd INTEGER DEFAULT 50,
        sponsors INTEGER DEFAULT 50,
        focus INTEGER DEFAULT 50,
        calmness INTEGER DEFAULT 50,
        clutchness INTEGER DEFAULT 50,
        confidence INTEGER DEFAULT 50,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create play_adjustments table
    await db.execute('''
      CREATE TABLE play_adjustments (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        match_id TEXT NOT NULL,
        short_name TEXT NOT NULL,
        description TEXT NOT NULL,
        situation TEXT NOT NULL,
        momentum TEXT NOT NULL,
        grid_position INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        outcome TEXT,
        FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');

    // Create practice_status table (tracks dismissed and "later" matches)
    await db.execute('''
      CREATE TABLE practice_status (
        match_id TEXT PRIMARY KEY,
        status TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');

    // Create ai_tactics table (AI-generated tactical suggestions)
    await db.execute('''
      CREATE TABLE ai_tactics (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        conversation_id TEXT NOT NULL,
        match_id TEXT NOT NULL,
        short_name TEXT NOT NULL,
        description TEXT NOT NULL,
        outcome TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
        FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');

    // Create practice_hidden table (tracks hidden tactics/adjustments in Practice)
    await db.execute('''
      CREATE TABLE practice_hidden (
        short_name TEXT PRIMARY KEY,
        hidden_at INTEGER NOT NULL
      )
    ''');

    // Create practice_drills table (AI-generated practice drills for tactics)
    await db.execute('''
      CREATE TABLE practice_drills (
        id TEXT PRIMARY KEY,
        tactic_short_name TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        duration TEXT,
        difficulty TEXT,
        order_index INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        movements TEXT,
        positions TEXT
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_matches_date ON matches(match_date DESC)');
    await db.execute(
        'CREATE INDEX idx_conversations_match_id ON conversations(match_id)');
    await db.execute(
        'CREATE INDEX idx_messages_conversation_id ON messages(conversation_id)');
    await db.execute(
        'CREATE INDEX idx_opponents_name ON opponents(name)');
    await db.execute(
        'CREATE INDEX idx_play_adjustments_match ON play_adjustments(match_id, situation, momentum)');
    await db.execute(
        'CREATE INDEX idx_ai_tactics_match ON ai_tactics(match_id)');
    await db.execute(
        'CREATE INDEX idx_ai_tactics_conversation ON ai_tactics(conversation_id)');
    await db.execute(
        'CREATE INDEX idx_practice_drills_tactic ON practice_drills(tactic_short_name)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations
    if (oldVersion < 2) {
      // Add user_id and last_synced columns to existing tables
      await db.execute('ALTER TABLE matches ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE matches ADD COLUMN last_synced INTEGER');
      await db.execute('ALTER TABLE conversations ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE conversations ADD COLUMN last_synced INTEGER');
      await db.execute('ALTER TABLE messages ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN last_synced INTEGER');
    }

    if (oldVersion < 3) {
      // Make match_date nullable in matches table
      // SQLite doesn't support ALTER COLUMN, so we need to recreate the table

      // 1. Create new table with updated schema
      await db.execute('''
        CREATE TABLE matches_new (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          opponent_name TEXT NOT NULL,
          match_date INTEGER,
          match_result TEXT,
          match_score_user INTEGER,
          match_score_opponent INTEGER,
          match_type TEXT,
          court_surface TEXT,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_synced INTEGER
        )
      ''');

      // 2. Copy data from old table to new table
      await db.execute('''
        INSERT INTO matches_new
        SELECT id, user_id, opponent_name, match_date, match_result,
               match_score_user, match_score_opponent, match_type,
               court_surface, notes, created_at, updated_at, last_synced
        FROM matches
      ''');

      // 3. Drop old table
      await db.execute('DROP TABLE matches');

      // 4. Rename new table to original name
      await db.execute('ALTER TABLE matches_new RENAME TO matches');

      // 5. Recreate index
      await db.execute('CREATE INDEX idx_matches_date ON matches(match_date DESC)');
    }

    if (oldVersion < 4) {
      // Add court_cover column to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN court_cover TEXT');
    }

    if (oldVersion < 5) {
      // Add court_conditions column to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN court_conditions TEXT');
    }

    if (oldVersion < 6) {
      // Add set_scores column to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN set_scores TEXT');
    }

    if (oldVersion < 7) {
      // Add balls column to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN balls TEXT');
    }

    if (oldVersion < 8) {
      // Add altitude column to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN altitude TEXT');
    }

    if (oldVersion < 9) {
      // Add crowd column to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN crowd TEXT');
    }

    if (oldVersion < 10) {
      // Add court_speed column to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN court_speed TEXT');
    }

    if (oldVersion < 11) {
      // Migrate legacy data values
      // Update "Clay" to "Red clay"
      await db.execute('''
        UPDATE matches
        SET court_surface = 'Red clay'
        WHERE court_surface = 'Clay'
      ''');

      // Remove legacy "High altitude" from conditions
      await db.execute('''
        UPDATE matches
        SET court_conditions = NULL
        WHERE court_conditions = 'High altitude'
      ''');
    }

    if (oldVersion < 12) {
      // Add opponent_name_2 and partner_name columns
      await db.execute('ALTER TABLE matches ADD COLUMN opponent_name_2 TEXT');
      await db.execute('ALTER TABLE matches ADD COLUMN partner_name TEXT');
    }

    if (oldVersion < 13) {
      // Create opponents table
      await db.execute('''
        CREATE TABLE opponents (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          agility INTEGER DEFAULT 50,
          mobility INTEGER DEFAULT 50,
          lean_body INTEGER DEFAULT 50,
          endurance INTEGER DEFAULT 50,
          power INTEGER DEFAULT 50,
          reach INTEGER DEFAULT 50,
          coordination INTEGER DEFAULT 50,
          balance INTEGER DEFAULT 50,
          serve INTEGER DEFAULT 50,
          return_serve INTEGER DEFAULT 50,
          forehand INTEGER DEFAULT 50,
          backhand INTEGER DEFAULT 50,
          transition INTEGER DEFAULT 50,
          net INTEGER DEFAULT 50,
          specialty INTEGER DEFAULT 50,
          counterpuncher INTEGER DEFAULT 50,
          aggressive_baseliner INTEGER DEFAULT 50,
          all_court_player INTEGER DEFAULT 50,
          net_rusher INTEGER DEFAULT 50,
          serve_and_volleyer INTEGER DEFAULT 50,
          big_server INTEGER DEFAULT 50,
          family INTEGER DEFAULT 50,
          coaches INTEGER DEFAULT 50,
          partners INTEGER DEFAULT 50,
          crowd INTEGER DEFAULT 50,
          sponsors INTEGER DEFAULT 50,
          focus INTEGER DEFAULT 50,
          calmness INTEGER DEFAULT 50,
          clutchness INTEGER DEFAULT 50,
          confidence INTEGER DEFAULT 50,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_opponents_name ON opponents(name)');
    }

    if (oldVersion < 14) {
      // Add court_name column to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN court_name TEXT');
    }

    if (oldVersion < 15) {
      // Add my_adjustment and opponent_adjustment columns to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN my_adjustment TEXT');
      await db.execute('ALTER TABLE matches ADD COLUMN opponent_adjustment TEXT');
    }

    if (oldVersion < 16) {
      // Add profile fields to opponents table
      await db.execute('ALTER TABLE opponents ADD COLUMN birth_year INTEGER');
      await db.execute('ALTER TABLE opponents ADD COLUMN height_cm INTEGER');
      await db.execute('ALTER TABLE opponents ADD COLUMN weight_kg REAL');
      await db.execute('ALTER TABLE opponents ADD COLUMN years_active TEXT');
      await db.execute('ALTER TABLE opponents ADD COLUMN hands TEXT');
      await db.execute('ALTER TABLE opponents ADD COLUMN backhand_type TEXT');
    }

    if (oldVersion < 17) {
      // Create user_profile table
      await db.execute('''
        CREATE TABLE user_profile (
          id TEXT PRIMARY KEY,
          birth_year INTEGER,
          height_cm INTEGER,
          weight_kg REAL,
          years_active TEXT,
          hands TEXT,
          backhand_type TEXT,
          agility INTEGER DEFAULT 50,
          mobility INTEGER DEFAULT 50,
          lean_body INTEGER DEFAULT 50,
          endurance INTEGER DEFAULT 50,
          power INTEGER DEFAULT 50,
          reach INTEGER DEFAULT 50,
          coordination INTEGER DEFAULT 50,
          balance INTEGER DEFAULT 50,
          serve INTEGER DEFAULT 50,
          return_serve INTEGER DEFAULT 50,
          forehand INTEGER DEFAULT 50,
          backhand INTEGER DEFAULT 50,
          transition INTEGER DEFAULT 50,
          net INTEGER DEFAULT 50,
          specialty INTEGER DEFAULT 50,
          counterpuncher INTEGER DEFAULT 50,
          aggressive_baseliner INTEGER DEFAULT 50,
          all_court_player INTEGER DEFAULT 50,
          net_rusher INTEGER DEFAULT 50,
          serve_and_volleyer INTEGER DEFAULT 50,
          big_server INTEGER DEFAULT 50,
          family INTEGER DEFAULT 50,
          coaches INTEGER DEFAULT 50,
          partners INTEGER DEFAULT 50,
          crowd INTEGER DEFAULT 50,
          sponsors INTEGER DEFAULT 50,
          focus INTEGER DEFAULT 50,
          calmness INTEGER DEFAULT 50,
          clutchness INTEGER DEFAULT 50,
          confidence INTEGER DEFAULT 50,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 18) {
      // Add match format columns to matches table
      await db.execute('ALTER TABLE matches ADD COLUMN match_format TEXT');
      await db.execute('ALTER TABLE matches ADD COLUMN no_ads INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE matches ADD COLUMN tiebreak_set INTEGER DEFAULT 0');
    }

    if (oldVersion < 19) {
      // Create play_adjustments table
      await db.execute('''
        CREATE TABLE play_adjustments (
          id TEXT PRIMARY KEY,
          match_id TEXT NOT NULL,
          short_name TEXT NOT NULL,
          description TEXT NOT NULL,
          situation TEXT NOT NULL,
          momentum TEXT NOT NULL,
          grid_position INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX idx_play_adjustments_match ON play_adjustments(match_id, situation, momentum)');
    }

    if (oldVersion < 20) {
      // Create practice_status table
      await db.execute('''
        CREATE TABLE practice_status (
          match_id TEXT PRIMARY KEY,
          status TEXT NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 21) {
      // Add is_accepted column to play_adjustments
      await db.execute('ALTER TABLE play_adjustments ADD COLUMN is_accepted INTEGER DEFAULT 0');
    }

    if (oldVersion < 22) {
      // Add outcome column to play_adjustments (replaces is_accepted)
      await db.execute('ALTER TABLE play_adjustments ADD COLUMN outcome TEXT');
    }

    if (oldVersion < 23) {
      // Add user_id columns for sync support
      await db.execute('ALTER TABLE opponents ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN user_id TEXT');
      await db.execute('ALTER TABLE play_adjustments ADD COLUMN user_id TEXT');
    }

    if (oldVersion < 24) {
      // Rename years_active to active_since_year
      await db.execute('ALTER TABLE opponents RENAME COLUMN years_active TO active_since_year');
      await db.execute('ALTER TABLE user_profile RENAME COLUMN years_active TO active_since_year');
    }

    if (oldVersion < 25) {
      // Create ai_tactics table for AI-generated tactical suggestions
      await db.execute('''
        CREATE TABLE ai_tactics (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          conversation_id TEXT NOT NULL,
          match_id TEXT NOT NULL,
          short_name TEXT NOT NULL,
          description TEXT NOT NULL,
          outcome TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
          FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_ai_tactics_match ON ai_tactics(match_id)');
      await db.execute('CREATE INDEX idx_ai_tactics_conversation ON ai_tactics(conversation_id)');
    }

    if (oldVersion < 26) {
      // Create practice_hidden table for tracking hidden tactics/adjustments
      await db.execute('''
        CREATE TABLE practice_hidden (
          short_name TEXT PRIMARY KEY,
          hidden_at INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 27) {
      // Add level column to user_profile and opponents tables
      await db.execute('ALTER TABLE user_profile ADD COLUMN level TEXT');
      await db.execute('ALTER TABLE opponents ADD COLUMN level TEXT');
    }

    if (oldVersion < 28) {
      // Create practice_drills table for AI-generated practice drills
      await db.execute('''
        CREATE TABLE practice_drills (
          id TEXT PRIMARY KEY,
          tactic_short_name TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          duration TEXT,
          difficulty TEXT,
          order_index INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_practice_drills_tactic ON practice_drills(tactic_short_name)');
    }

    if (oldVersion < 29) {
      // Add movements and positions columns to practice_drills for court diagrams
      await db.execute('ALTER TABLE practice_drills ADD COLUMN movements TEXT');
      await db.execute('ALTER TABLE practice_drills ADD COLUMN positions TEXT');
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
      String sql, List<dynamic>? arguments) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Utility methods
  Future<int> getTableCount(String table) async {
    final result = await rawQuery('SELECT COUNT(*) as count FROM $table', null);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('conversations');
    await db.delete('matches');
  }
}
