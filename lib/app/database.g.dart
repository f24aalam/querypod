// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorkspacesTable extends Workspaces
    with TableInfo<$WorkspacesTable, WorkspaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WorkspacesTable createAlias(String alias) {
    return $WorkspacesTable(attachedDatabase, alias);
  }
}

class WorkspaceRow extends DataClass implements Insertable<WorkspaceRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WorkspaceRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkspaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorkspaceRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkspaceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkspaceRow copyWithCompanion(WorkspacesCompanion data) {
    return WorkspaceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkspacesCompanion extends UpdateCompanion<WorkspaceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkspaceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectionsTable extends Connections
    with TableInfo<$ConnectionsTable, ConnectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userMeta = const VerificationMeta('user');
  @override
  late final GeneratedColumn<String> user = GeneratedColumn<String>(
    'user',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _databaseMeta = const VerificationMeta(
    'database',
  );
  @override
  late final GeneratedColumn<String> database = GeneratedColumn<String>(
    'database',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionTypeMeta = const VerificationMeta(
    'connectionType',
  );
  @override
  late final GeneratedColumn<String> connectionType = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useTlsMeta = const VerificationMeta('useTls');
  @override
  late final GeneratedColumn<bool> useTls = GeneratedColumn<bool>(
    'use_tls',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_tls" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    name,
    host,
    port,
    user,
    database,
    connectionType,
    useTls,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConnectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('user')) {
      context.handle(
        _userMeta,
        user.isAcceptableOrUnknown(data['user']!, _userMeta),
      );
    } else if (isInserting) {
      context.missing(_userMeta);
    }
    if (data.containsKey('database')) {
      context.handle(
        _databaseMeta,
        database.isAcceptableOrUnknown(data['database']!, _databaseMeta),
      );
    } else if (isInserting) {
      context.missing(_databaseMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _connectionTypeMeta,
        connectionType.isAcceptableOrUnknown(
          data['type']!,
          _connectionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionTypeMeta);
    }
    if (data.containsKey('use_tls')) {
      context.handle(
        _useTlsMeta,
        useTls.isAcceptableOrUnknown(data['use_tls']!, _useTlsMeta),
      );
    } else if (isInserting) {
      context.missing(_useTlsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      user: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user'],
      )!,
      database: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}database'],
      )!,
      connectionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      useTls: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_tls'],
      )!,
    );
  }

  @override
  $ConnectionsTable createAlias(String alias) {
    return $ConnectionsTable(attachedDatabase, alias);
  }
}

class ConnectionRow extends DataClass implements Insertable<ConnectionRow> {
  final String id;
  final String workspaceId;
  final String name;
  final String host;
  final int port;
  final String user;
  final String database;
  final String connectionType;
  final bool useTls;
  const ConnectionRow({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.host,
    required this.port,
    required this.user,
    required this.database,
    required this.connectionType,
    required this.useTls,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['user'] = Variable<String>(user);
    map['database'] = Variable<String>(database);
    map['type'] = Variable<String>(connectionType);
    map['use_tls'] = Variable<bool>(useTls);
    return map;
  }

  ConnectionsCompanion toCompanion(bool nullToAbsent) {
    return ConnectionsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      name: Value(name),
      host: Value(host),
      port: Value(port),
      user: Value(user),
      database: Value(database),
      connectionType: Value(connectionType),
      useTls: Value(useTls),
    );
  }

  factory ConnectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionRow(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      user: serializer.fromJson<String>(json['user']),
      database: serializer.fromJson<String>(json['database']),
      connectionType: serializer.fromJson<String>(json['connectionType']),
      useTls: serializer.fromJson<bool>(json['useTls']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'user': serializer.toJson<String>(user),
      'database': serializer.toJson<String>(database),
      'connectionType': serializer.toJson<String>(connectionType),
      'useTls': serializer.toJson<bool>(useTls),
    };
  }

  ConnectionRow copyWith({
    String? id,
    String? workspaceId,
    String? name,
    String? host,
    int? port,
    String? user,
    String? database,
    String? connectionType,
    bool? useTls,
  }) => ConnectionRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    host: host ?? this.host,
    port: port ?? this.port,
    user: user ?? this.user,
    database: database ?? this.database,
    connectionType: connectionType ?? this.connectionType,
    useTls: useTls ?? this.useTls,
  );
  ConnectionRow copyWithCompanion(ConnectionsCompanion data) {
    return ConnectionRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      user: data.user.present ? data.user.value : this.user,
      database: data.database.present ? data.database.value : this.database,
      connectionType: data.connectionType.present
          ? data.connectionType.value
          : this.connectionType,
      useTls: data.useTls.present ? data.useTls.value : this.useTls,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('user: $user, ')
          ..write('database: $database, ')
          ..write('connectionType: $connectionType, ')
          ..write('useTls: $useTls')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    host,
    port,
    user,
    database,
    connectionType,
    useTls,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.host == this.host &&
          other.port == this.port &&
          other.user == this.user &&
          other.database == this.database &&
          other.connectionType == this.connectionType &&
          other.useTls == this.useTls);
}

class ConnectionsCompanion extends UpdateCompanion<ConnectionRow> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String> host;
  final Value<int> port;
  final Value<String> user;
  final Value<String> database;
  final Value<String> connectionType;
  final Value<bool> useTls;
  final Value<int> rowid;
  const ConnectionsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.user = const Value.absent(),
    this.database = const Value.absent(),
    this.connectionType = const Value.absent(),
    this.useTls = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionsCompanion.insert({
    required String id,
    required String workspaceId,
    required String name,
    required String host,
    required int port,
    required String user,
    required String database,
    required String connectionType,
    required bool useTls,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name),
       host = Value(host),
       port = Value(port),
       user = Value(user),
       database = Value(database),
       connectionType = Value(connectionType),
       useTls = Value(useTls);
  static Insertable<ConnectionRow> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? user,
    Expression<String>? database,
    Expression<String>? connectionType,
    Expression<bool>? useTls,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (user != null) 'user': user,
      if (database != null) 'database': database,
      if (connectionType != null) 'type': connectionType,
      if (useTls != null) 'use_tls': useTls,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<String>? host,
    Value<int>? port,
    Value<String>? user,
    Value<String>? database,
    Value<String>? connectionType,
    Value<bool>? useTls,
    Value<int>? rowid,
  }) {
    return ConnectionsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      user: user ?? this.user,
      database: database ?? this.database,
      connectionType: connectionType ?? this.connectionType,
      useTls: useTls ?? this.useTls,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (user.present) {
      map['user'] = Variable<String>(user.value);
    }
    if (database.present) {
      map['database'] = Variable<String>(database.value);
    }
    if (connectionType.present) {
      map['type'] = Variable<String>(connectionType.value);
    }
    if (useTls.present) {
      map['use_tls'] = Variable<bool>(useTls.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('user: $user, ')
          ..write('database: $database, ')
          ..write('connectionType: $connectionType, ')
          ..write('useTls: $useTls, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedQueriesTable extends SavedQueries
    with TableInfo<$SavedQueriesTable, SavedQueryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedQueriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<String> connectionId = GeneratedColumn<String>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sqlMeta = const VerificationMeta('sql');
  @override
  late final GeneratedColumn<String> sql = GeneratedColumn<String>(
    'sql',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _databaseMeta = const VerificationMeta(
    'database',
  );
  @override
  late final GeneratedColumn<String> database = GeneratedColumn<String>(
    'database',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _querySchemaMeta = const VerificationMeta(
    'querySchema',
  );
  @override
  late final GeneratedColumn<String> querySchema = GeneratedColumn<String>(
    'schema',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    connectionId,
    title,
    sql,
    database,
    querySchema,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_queries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedQueryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('sql')) {
      context.handle(
        _sqlMeta,
        sql.isAcceptableOrUnknown(data['sql']!, _sqlMeta),
      );
    } else if (isInserting) {
      context.missing(_sqlMeta);
    }
    if (data.containsKey('database')) {
      context.handle(
        _databaseMeta,
        database.isAcceptableOrUnknown(data['database']!, _databaseMeta),
      );
    }
    if (data.containsKey('schema')) {
      context.handle(
        _querySchemaMeta,
        querySchema.isAcceptableOrUnknown(data['schema']!, _querySchemaMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedQueryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedQueryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sql: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sql'],
      )!,
      database: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}database'],
      ),
      querySchema: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SavedQueriesTable createAlias(String alias) {
    return $SavedQueriesTable(attachedDatabase, alias);
  }
}

class SavedQueryRow extends DataClass implements Insertable<SavedQueryRow> {
  final String id;
  final String connectionId;
  final String title;
  final String sql;
  final String? database;
  final String? querySchema;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SavedQueryRow({
    required this.id,
    required this.connectionId,
    required this.title,
    required this.sql,
    this.database,
    this.querySchema,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['connection_id'] = Variable<String>(connectionId);
    map['title'] = Variable<String>(title);
    map['sql'] = Variable<String>(sql);
    if (!nullToAbsent || database != null) {
      map['database'] = Variable<String>(database);
    }
    if (!nullToAbsent || querySchema != null) {
      map['schema'] = Variable<String>(querySchema);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavedQueriesCompanion toCompanion(bool nullToAbsent) {
    return SavedQueriesCompanion(
      id: Value(id),
      connectionId: Value(connectionId),
      title: Value(title),
      sql: Value(sql),
      database: database == null && nullToAbsent
          ? const Value.absent()
          : Value(database),
      querySchema: querySchema == null && nullToAbsent
          ? const Value.absent()
          : Value(querySchema),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedQueryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedQueryRow(
      id: serializer.fromJson<String>(json['id']),
      connectionId: serializer.fromJson<String>(json['connectionId']),
      title: serializer.fromJson<String>(json['title']),
      sql: serializer.fromJson<String>(json['sql']),
      database: serializer.fromJson<String?>(json['database']),
      querySchema: serializer.fromJson<String?>(json['querySchema']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'connectionId': serializer.toJson<String>(connectionId),
      'title': serializer.toJson<String>(title),
      'sql': serializer.toJson<String>(sql),
      'database': serializer.toJson<String?>(database),
      'querySchema': serializer.toJson<String?>(querySchema),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedQueryRow copyWith({
    String? id,
    String? connectionId,
    String? title,
    String? sql,
    Value<String?> database = const Value.absent(),
    Value<String?> querySchema = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavedQueryRow(
    id: id ?? this.id,
    connectionId: connectionId ?? this.connectionId,
    title: title ?? this.title,
    sql: sql ?? this.sql,
    database: database.present ? database.value : this.database,
    querySchema: querySchema.present ? querySchema.value : this.querySchema,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedQueryRow copyWithCompanion(SavedQueriesCompanion data) {
    return SavedQueryRow(
      id: data.id.present ? data.id.value : this.id,
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      title: data.title.present ? data.title.value : this.title,
      sql: data.sql.present ? data.sql.value : this.sql,
      database: data.database.present ? data.database.value : this.database,
      querySchema: data.querySchema.present
          ? data.querySchema.value
          : this.querySchema,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedQueryRow(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('title: $title, ')
          ..write('sql: $sql, ')
          ..write('database: $database, ')
          ..write('querySchema: $querySchema, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    connectionId,
    title,
    sql,
    database,
    querySchema,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedQueryRow &&
          other.id == this.id &&
          other.connectionId == this.connectionId &&
          other.title == this.title &&
          other.sql == this.sql &&
          other.database == this.database &&
          other.querySchema == this.querySchema &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SavedQueriesCompanion extends UpdateCompanion<SavedQueryRow> {
  final Value<String> id;
  final Value<String> connectionId;
  final Value<String> title;
  final Value<String> sql;
  final Value<String?> database;
  final Value<String?> querySchema;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SavedQueriesCompanion({
    this.id = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.title = const Value.absent(),
    this.sql = const Value.absent(),
    this.database = const Value.absent(),
    this.querySchema = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedQueriesCompanion.insert({
    required String id,
    required String connectionId,
    required String title,
    required String sql,
    this.database = const Value.absent(),
    this.querySchema = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       connectionId = Value(connectionId),
       title = Value(title),
       sql = Value(sql),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SavedQueryRow> custom({
    Expression<String>? id,
    Expression<String>? connectionId,
    Expression<String>? title,
    Expression<String>? sql,
    Expression<String>? database,
    Expression<String>? querySchema,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (connectionId != null) 'connection_id': connectionId,
      if (title != null) 'title': title,
      if (sql != null) 'sql': sql,
      if (database != null) 'database': database,
      if (querySchema != null) 'schema': querySchema,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedQueriesCompanion copyWith({
    Value<String>? id,
    Value<String>? connectionId,
    Value<String>? title,
    Value<String>? sql,
    Value<String?>? database,
    Value<String?>? querySchema,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SavedQueriesCompanion(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      title: title ?? this.title,
      sql: sql ?? this.sql,
      database: database ?? this.database,
      querySchema: querySchema ?? this.querySchema,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (connectionId.present) {
      map['connection_id'] = Variable<String>(connectionId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sql.present) {
      map['sql'] = Variable<String>(sql.value);
    }
    if (database.present) {
      map['database'] = Variable<String>(database.value);
    }
    if (querySchema.present) {
      map['schema'] = Variable<String>(querySchema.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedQueriesCompanion(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('title: $title, ')
          ..write('sql: $sql, ')
          ..write('database: $database, ')
          ..write('querySchema: $querySchema, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueryHistoryEntriesTable extends QueryHistoryEntries
    with TableInfo<$QueryHistoryEntriesTable, QueryHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueryHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<String> connectionId = GeneratedColumn<String>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sqlMeta = const VerificationMeta('sql');
  @override
  late final GeneratedColumn<String> sql = GeneratedColumn<String>(
    'sql',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _executionTimeMsMeta = const VerificationMeta(
    'executionTimeMs',
  );
  @override
  late final GeneratedColumn<int> executionTimeMs = GeneratedColumn<int>(
    'execution_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    connectionId,
    sourceType,
    sourceId,
    sql,
    executionTimeMs,
    status,
    errorMessage,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'query_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueryHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('sql')) {
      context.handle(
        _sqlMeta,
        sql.isAcceptableOrUnknown(data['sql']!, _sqlMeta),
      );
    } else if (isInserting) {
      context.missing(_sqlMeta);
    }
    if (data.containsKey('execution_time_ms')) {
      context.handle(
        _executionTimeMsMeta,
        executionTimeMs.isAcceptableOrUnknown(
          data['execution_time_ms']!,
          _executionTimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_executionTimeMsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueryHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueryHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_id'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      sql: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sql'],
      )!,
      executionTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}execution_time_ms'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QueryHistoryEntriesTable createAlias(String alias) {
    return $QueryHistoryEntriesTable(attachedDatabase, alias);
  }
}

class QueryHistoryRow extends DataClass implements Insertable<QueryHistoryRow> {
  final String id;
  final String connectionId;
  final String sourceType;
  final String? sourceId;
  final String sql;
  final int executionTimeMs;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;
  const QueryHistoryRow({
    required this.id,
    required this.connectionId,
    required this.sourceType,
    this.sourceId,
    required this.sql,
    required this.executionTimeMs,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['connection_id'] = Variable<String>(connectionId);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['sql'] = Variable<String>(sql);
    map['execution_time_ms'] = Variable<int>(executionTimeMs);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QueryHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return QueryHistoryEntriesCompanion(
      id: Value(id),
      connectionId: Value(connectionId),
      sourceType: Value(sourceType),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      sql: Value(sql),
      executionTimeMs: Value(executionTimeMs),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
    );
  }

  factory QueryHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueryHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      connectionId: serializer.fromJson<String>(json['connectionId']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      sql: serializer.fromJson<String>(json['sql']),
      executionTimeMs: serializer.fromJson<int>(json['executionTimeMs']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'connectionId': serializer.toJson<String>(connectionId),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String?>(sourceId),
      'sql': serializer.toJson<String>(sql),
      'executionTimeMs': serializer.toJson<int>(executionTimeMs),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QueryHistoryRow copyWith({
    String? id,
    String? connectionId,
    String? sourceType,
    Value<String?> sourceId = const Value.absent(),
    String? sql,
    int? executionTimeMs,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
  }) => QueryHistoryRow(
    id: id ?? this.id,
    connectionId: connectionId ?? this.connectionId,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    sql: sql ?? this.sql,
    executionTimeMs: executionTimeMs ?? this.executionTimeMs,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
  );
  QueryHistoryRow copyWithCompanion(QueryHistoryEntriesCompanion data) {
    return QueryHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sql: data.sql.present ? data.sql.value : this.sql,
      executionTimeMs: data.executionTimeMs.present
          ? data.executionTimeMs.value
          : this.executionTimeMs,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueryHistoryRow(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('sql: $sql, ')
          ..write('executionTimeMs: $executionTimeMs, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    connectionId,
    sourceType,
    sourceId,
    sql,
    executionTimeMs,
    status,
    errorMessage,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueryHistoryRow &&
          other.id == this.id &&
          other.connectionId == this.connectionId &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.sql == this.sql &&
          other.executionTimeMs == this.executionTimeMs &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt);
}

class QueryHistoryEntriesCompanion extends UpdateCompanion<QueryHistoryRow> {
  final Value<String> id;
  final Value<String> connectionId;
  final Value<String> sourceType;
  final Value<String?> sourceId;
  final Value<String> sql;
  final Value<int> executionTimeMs;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const QueryHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.connectionId = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sql = const Value.absent(),
    this.executionTimeMs = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueryHistoryEntriesCompanion.insert({
    required String id,
    required String connectionId,
    required String sourceType,
    this.sourceId = const Value.absent(),
    required String sql,
    required int executionTimeMs,
    required String status,
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       connectionId = Value(connectionId),
       sourceType = Value(sourceType),
       sql = Value(sql),
       executionTimeMs = Value(executionTimeMs),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<QueryHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? connectionId,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? sql,
    Expression<int>? executionTimeMs,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (connectionId != null) 'connection_id': connectionId,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (sql != null) 'sql': sql,
      if (executionTimeMs != null) 'execution_time_ms': executionTimeMs,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueryHistoryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? connectionId,
    Value<String>? sourceType,
    Value<String?>? sourceId,
    Value<String>? sql,
    Value<int>? executionTimeMs,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return QueryHistoryEntriesCompanion(
      id: id ?? this.id,
      connectionId: connectionId ?? this.connectionId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      sql: sql ?? this.sql,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (connectionId.present) {
      map['connection_id'] = Variable<String>(connectionId.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sql.present) {
      map['sql'] = Variable<String>(sql.value);
    }
    if (executionTimeMs.present) {
      map['execution_time_ms'] = Variable<int>(executionTimeMs.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueryHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('connectionId: $connectionId, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('sql: $sql, ')
          ..write('executionTimeMs: $executionTimeMs, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PinnedTablesTable extends PinnedTables
    with TableInfo<$PinnedTablesTable, PinnedTableRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PinnedTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<String> connectionId = GeneratedColumn<String>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _databaseMeta = const VerificationMeta(
    'database',
  );
  @override
  late final GeneratedColumn<String> database = GeneratedColumn<String>(
    'database',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pgSchemaMeta = const VerificationMeta(
    'pgSchema',
  );
  @override
  late final GeneratedColumn<String> pgSchema = GeneratedColumn<String>(
    'schema',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('public'),
  );
  static const VerificationMeta _tableMeta = const VerificationMeta('table');
  @override
  late final GeneratedColumn<String> table = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    connectionId,
    database,
    pgSchema,
    table,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pinned_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<PinnedTableRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('database')) {
      context.handle(
        _databaseMeta,
        database.isAcceptableOrUnknown(data['database']!, _databaseMeta),
      );
    } else if (isInserting) {
      context.missing(_databaseMeta);
    }
    if (data.containsKey('schema')) {
      context.handle(
        _pgSchemaMeta,
        pgSchema.isAcceptableOrUnknown(data['schema']!, _pgSchemaMeta),
      );
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _tableMeta,
        table.isAcceptableOrUnknown(data['table_name']!, _tableMeta),
      );
    } else if (isInserting) {
      context.missing(_tableMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    connectionId,
    database,
    pgSchema,
    table,
  };
  @override
  PinnedTableRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PinnedTableRow(
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_id'],
      )!,
      database: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}database'],
      )!,
      pgSchema: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema'],
      )!,
      table: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $PinnedTablesTable createAlias(String alias) {
    return $PinnedTablesTable(attachedDatabase, alias);
  }
}

class PinnedTableRow extends DataClass implements Insertable<PinnedTableRow> {
  final String connectionId;
  final String database;
  final String pgSchema;
  final String table;
  final int sortOrder;
  const PinnedTableRow({
    required this.connectionId,
    required this.database,
    required this.pgSchema,
    required this.table,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<String>(connectionId);
    map['database'] = Variable<String>(database);
    map['schema'] = Variable<String>(pgSchema);
    map['table_name'] = Variable<String>(table);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PinnedTablesCompanion toCompanion(bool nullToAbsent) {
    return PinnedTablesCompanion(
      connectionId: Value(connectionId),
      database: Value(database),
      pgSchema: Value(pgSchema),
      table: Value(table),
      sortOrder: Value(sortOrder),
    );
  }

  factory PinnedTableRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PinnedTableRow(
      connectionId: serializer.fromJson<String>(json['connectionId']),
      database: serializer.fromJson<String>(json['database']),
      pgSchema: serializer.fromJson<String>(json['pgSchema']),
      table: serializer.fromJson<String>(json['table']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<String>(connectionId),
      'database': serializer.toJson<String>(database),
      'pgSchema': serializer.toJson<String>(pgSchema),
      'table': serializer.toJson<String>(table),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PinnedTableRow copyWith({
    String? connectionId,
    String? database,
    String? pgSchema,
    String? table,
    int? sortOrder,
  }) => PinnedTableRow(
    connectionId: connectionId ?? this.connectionId,
    database: database ?? this.database,
    pgSchema: pgSchema ?? this.pgSchema,
    table: table ?? this.table,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  PinnedTableRow copyWithCompanion(PinnedTablesCompanion data) {
    return PinnedTableRow(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      database: data.database.present ? data.database.value : this.database,
      pgSchema: data.pgSchema.present ? data.pgSchema.value : this.pgSchema,
      table: data.table.present ? data.table.value : this.table,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PinnedTableRow(')
          ..write('connectionId: $connectionId, ')
          ..write('database: $database, ')
          ..write('pgSchema: $pgSchema, ')
          ..write('table: $table, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(connectionId, database, pgSchema, table, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PinnedTableRow &&
          other.connectionId == this.connectionId &&
          other.database == this.database &&
          other.pgSchema == this.pgSchema &&
          other.table == this.table &&
          other.sortOrder == this.sortOrder);
}

class PinnedTablesCompanion extends UpdateCompanion<PinnedTableRow> {
  final Value<String> connectionId;
  final Value<String> database;
  final Value<String> pgSchema;
  final Value<String> table;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const PinnedTablesCompanion({
    this.connectionId = const Value.absent(),
    this.database = const Value.absent(),
    this.pgSchema = const Value.absent(),
    this.table = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PinnedTablesCompanion.insert({
    required String connectionId,
    required String database,
    this.pgSchema = const Value.absent(),
    required String table,
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : connectionId = Value(connectionId),
       database = Value(database),
       table = Value(table),
       sortOrder = Value(sortOrder);
  static Insertable<PinnedTableRow> custom({
    Expression<String>? connectionId,
    Expression<String>? database,
    Expression<String>? pgSchema,
    Expression<String>? table,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (database != null) 'database': database,
      if (pgSchema != null) 'schema': pgSchema,
      if (table != null) 'table_name': table,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PinnedTablesCompanion copyWith({
    Value<String>? connectionId,
    Value<String>? database,
    Value<String>? pgSchema,
    Value<String>? table,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return PinnedTablesCompanion(
      connectionId: connectionId ?? this.connectionId,
      database: database ?? this.database,
      pgSchema: pgSchema ?? this.pgSchema,
      table: table ?? this.table,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<String>(connectionId.value);
    }
    if (database.present) {
      map['database'] = Variable<String>(database.value);
    }
    if (pgSchema.present) {
      map['schema'] = Variable<String>(pgSchema.value);
    }
    if (table.present) {
      map['table_name'] = Variable<String>(table.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PinnedTablesCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('database: $database, ')
          ..write('pgSchema: $pgSchema, ')
          ..write('table: $table, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SelectedSchemasTable extends SelectedSchemas
    with TableInfo<$SelectedSchemasTable, SelectedSchemaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SelectedSchemasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionIdMeta = const VerificationMeta(
    'connectionId',
  );
  @override
  late final GeneratedColumn<String> connectionId = GeneratedColumn<String>(
    'connection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES connections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _databaseMeta = const VerificationMeta(
    'database',
  );
  @override
  late final GeneratedColumn<String> database = GeneratedColumn<String>(
    'database',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pgSchemaMeta = const VerificationMeta(
    'pgSchema',
  );
  @override
  late final GeneratedColumn<String> pgSchema = GeneratedColumn<String>(
    'schema',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [connectionId, database, pgSchema];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'selected_schemas';
  @override
  VerificationContext validateIntegrity(
    Insertable<SelectedSchemaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_id')) {
      context.handle(
        _connectionIdMeta,
        connectionId.isAcceptableOrUnknown(
          data['connection_id']!,
          _connectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionIdMeta);
    }
    if (data.containsKey('database')) {
      context.handle(
        _databaseMeta,
        database.isAcceptableOrUnknown(data['database']!, _databaseMeta),
      );
    } else if (isInserting) {
      context.missing(_databaseMeta);
    }
    if (data.containsKey('schema')) {
      context.handle(
        _pgSchemaMeta,
        pgSchema.isAcceptableOrUnknown(data['schema']!, _pgSchemaMeta),
      );
    } else if (isInserting) {
      context.missing(_pgSchemaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {connectionId, database};
  @override
  SelectedSchemaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SelectedSchemaRow(
      connectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_id'],
      )!,
      database: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}database'],
      )!,
      pgSchema: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema'],
      )!,
    );
  }

  @override
  $SelectedSchemasTable createAlias(String alias) {
    return $SelectedSchemasTable(attachedDatabase, alias);
  }
}

class SelectedSchemaRow extends DataClass
    implements Insertable<SelectedSchemaRow> {
  final String connectionId;
  final String database;
  final String pgSchema;
  const SelectedSchemaRow({
    required this.connectionId,
    required this.database,
    required this.pgSchema,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_id'] = Variable<String>(connectionId);
    map['database'] = Variable<String>(database);
    map['schema'] = Variable<String>(pgSchema);
    return map;
  }

  SelectedSchemasCompanion toCompanion(bool nullToAbsent) {
    return SelectedSchemasCompanion(
      connectionId: Value(connectionId),
      database: Value(database),
      pgSchema: Value(pgSchema),
    );
  }

  factory SelectedSchemaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SelectedSchemaRow(
      connectionId: serializer.fromJson<String>(json['connectionId']),
      database: serializer.fromJson<String>(json['database']),
      pgSchema: serializer.fromJson<String>(json['pgSchema']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionId': serializer.toJson<String>(connectionId),
      'database': serializer.toJson<String>(database),
      'pgSchema': serializer.toJson<String>(pgSchema),
    };
  }

  SelectedSchemaRow copyWith({
    String? connectionId,
    String? database,
    String? pgSchema,
  }) => SelectedSchemaRow(
    connectionId: connectionId ?? this.connectionId,
    database: database ?? this.database,
    pgSchema: pgSchema ?? this.pgSchema,
  );
  SelectedSchemaRow copyWithCompanion(SelectedSchemasCompanion data) {
    return SelectedSchemaRow(
      connectionId: data.connectionId.present
          ? data.connectionId.value
          : this.connectionId,
      database: data.database.present ? data.database.value : this.database,
      pgSchema: data.pgSchema.present ? data.pgSchema.value : this.pgSchema,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SelectedSchemaRow(')
          ..write('connectionId: $connectionId, ')
          ..write('database: $database, ')
          ..write('pgSchema: $pgSchema')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(connectionId, database, pgSchema);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectedSchemaRow &&
          other.connectionId == this.connectionId &&
          other.database == this.database &&
          other.pgSchema == this.pgSchema);
}

class SelectedSchemasCompanion extends UpdateCompanion<SelectedSchemaRow> {
  final Value<String> connectionId;
  final Value<String> database;
  final Value<String> pgSchema;
  final Value<int> rowid;
  const SelectedSchemasCompanion({
    this.connectionId = const Value.absent(),
    this.database = const Value.absent(),
    this.pgSchema = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SelectedSchemasCompanion.insert({
    required String connectionId,
    required String database,
    required String pgSchema,
    this.rowid = const Value.absent(),
  }) : connectionId = Value(connectionId),
       database = Value(database),
       pgSchema = Value(pgSchema);
  static Insertable<SelectedSchemaRow> custom({
    Expression<String>? connectionId,
    Expression<String>? database,
    Expression<String>? pgSchema,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionId != null) 'connection_id': connectionId,
      if (database != null) 'database': database,
      if (pgSchema != null) 'schema': pgSchema,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SelectedSchemasCompanion copyWith({
    Value<String>? connectionId,
    Value<String>? database,
    Value<String>? pgSchema,
    Value<int>? rowid,
  }) {
    return SelectedSchemasCompanion(
      connectionId: connectionId ?? this.connectionId,
      database: database ?? this.database,
      pgSchema: pgSchema ?? this.pgSchema,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionId.present) {
      map['connection_id'] = Variable<String>(connectionId.value);
    }
    if (database.present) {
      map['database'] = Variable<String>(database.value);
    }
    if (pgSchema.present) {
      map['schema'] = Variable<String>(pgSchema.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SelectedSchemasCompanion(')
          ..write('connectionId: $connectionId, ')
          ..write('database: $database, ')
          ..write('pgSchema: $pgSchema, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppStateEntriesTable extends AppStateEntries
    with TableInfo<$AppStateEntriesTable, AppStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppStateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _selectedConnectionIdMeta =
      const VerificationMeta('selectedConnectionId');
  @override
  late final GeneratedColumn<String> selectedConnectionId =
      GeneratedColumn<String>(
        'selected_connection_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES connections (id) ON DELETE SET NULL',
        ),
      );
  static const VerificationMeta _zoomLevelMeta = const VerificationMeta(
    'zoomLevel',
  );
  @override
  late final GeneratedColumn<int> zoomLevel = GeneratedColumn<int>(
    'zoom_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, selectedConnectionId, zoomLevel];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('selected_connection_id')) {
      context.handle(
        _selectedConnectionIdMeta,
        selectedConnectionId.isAcceptableOrUnknown(
          data['selected_connection_id']!,
          _selectedConnectionIdMeta,
        ),
      );
    }
    if (data.containsKey('zoom_level')) {
      context.handle(
        _zoomLevelMeta,
        zoomLevel.isAcceptableOrUnknown(data['zoom_level']!, _zoomLevelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      selectedConnectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_connection_id'],
      ),
      zoomLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zoom_level'],
      )!,
    );
  }

  @override
  $AppStateEntriesTable createAlias(String alias) {
    return $AppStateEntriesTable(attachedDatabase, alias);
  }
}

class AppStateRow extends DataClass implements Insertable<AppStateRow> {
  final int id;
  final String? selectedConnectionId;
  final int zoomLevel;
  const AppStateRow({
    required this.id,
    this.selectedConnectionId,
    required this.zoomLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || selectedConnectionId != null) {
      map['selected_connection_id'] = Variable<String>(selectedConnectionId);
    }
    map['zoom_level'] = Variable<int>(zoomLevel);
    return map;
  }

  AppStateEntriesCompanion toCompanion(bool nullToAbsent) {
    return AppStateEntriesCompanion(
      id: Value(id),
      selectedConnectionId: selectedConnectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedConnectionId),
      zoomLevel: Value(zoomLevel),
    );
  }

  factory AppStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppStateRow(
      id: serializer.fromJson<int>(json['id']),
      selectedConnectionId: serializer.fromJson<String?>(
        json['selectedConnectionId'],
      ),
      zoomLevel: serializer.fromJson<int>(json['zoomLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'selectedConnectionId': serializer.toJson<String?>(selectedConnectionId),
      'zoomLevel': serializer.toJson<int>(zoomLevel),
    };
  }

  AppStateRow copyWith({
    int? id,
    Value<String?> selectedConnectionId = const Value.absent(),
    int? zoomLevel,
  }) => AppStateRow(
    id: id ?? this.id,
    selectedConnectionId: selectedConnectionId.present
        ? selectedConnectionId.value
        : this.selectedConnectionId,
    zoomLevel: zoomLevel ?? this.zoomLevel,
  );
  AppStateRow copyWithCompanion(AppStateEntriesCompanion data) {
    return AppStateRow(
      id: data.id.present ? data.id.value : this.id,
      selectedConnectionId: data.selectedConnectionId.present
          ? data.selectedConnectionId.value
          : this.selectedConnectionId,
      zoomLevel: data.zoomLevel.present ? data.zoomLevel.value : this.zoomLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppStateRow(')
          ..write('id: $id, ')
          ..write('selectedConnectionId: $selectedConnectionId, ')
          ..write('zoomLevel: $zoomLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, selectedConnectionId, zoomLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppStateRow &&
          other.id == this.id &&
          other.selectedConnectionId == this.selectedConnectionId &&
          other.zoomLevel == this.zoomLevel);
}

class AppStateEntriesCompanion extends UpdateCompanion<AppStateRow> {
  final Value<int> id;
  final Value<String?> selectedConnectionId;
  final Value<int> zoomLevel;
  const AppStateEntriesCompanion({
    this.id = const Value.absent(),
    this.selectedConnectionId = const Value.absent(),
    this.zoomLevel = const Value.absent(),
  });
  AppStateEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.selectedConnectionId = const Value.absent(),
    this.zoomLevel = const Value.absent(),
  });
  static Insertable<AppStateRow> custom({
    Expression<int>? id,
    Expression<String>? selectedConnectionId,
    Expression<int>? zoomLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (selectedConnectionId != null)
        'selected_connection_id': selectedConnectionId,
      if (zoomLevel != null) 'zoom_level': zoomLevel,
    });
  }

  AppStateEntriesCompanion copyWith({
    Value<int>? id,
    Value<String?>? selectedConnectionId,
    Value<int>? zoomLevel,
  }) {
    return AppStateEntriesCompanion(
      id: id ?? this.id,
      selectedConnectionId: selectedConnectionId ?? this.selectedConnectionId,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (selectedConnectionId.present) {
      map['selected_connection_id'] = Variable<String>(
        selectedConnectionId.value,
      );
    }
    if (zoomLevel.present) {
      map['zoom_level'] = Variable<int>(zoomLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppStateEntriesCompanion(')
          ..write('id: $id, ')
          ..write('selectedConnectionId: $selectedConnectionId, ')
          ..write('zoomLevel: $zoomLevel')
          ..write(')'))
        .toString();
  }
}

abstract class _$QueryPodDatabase extends GeneratedDatabase {
  _$QueryPodDatabase(QueryExecutor e) : super(e);
  $QueryPodDatabaseManager get managers => $QueryPodDatabaseManager(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $ConnectionsTable connections = $ConnectionsTable(this);
  late final $SavedQueriesTable savedQueries = $SavedQueriesTable(this);
  late final $QueryHistoryEntriesTable queryHistoryEntries =
      $QueryHistoryEntriesTable(this);
  late final $PinnedTablesTable pinnedTables = $PinnedTablesTable(this);
  late final $SelectedSchemasTable selectedSchemas = $SelectedSchemasTable(
    this,
  );
  late final $AppStateEntriesTable appStateEntries = $AppStateEntriesTable(
    this,
  );
  late final Index idxConnectionsWorkspaceId = Index(
    'idx_connections_workspace_id',
    'CREATE INDEX idx_connections_workspace_id ON connections (workspace_id)',
  );
  late final Index idxSavedQueriesConnectionId = Index(
    'idx_saved_queries_connection_id',
    'CREATE INDEX idx_saved_queries_connection_id ON saved_queries (connection_id, created_at)',
  );
  late final Index idxQueryHistoryConnectionId = Index(
    'idx_query_history_connection_id',
    'CREATE INDEX idx_query_history_connection_id ON query_history (connection_id, created_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    connections,
    savedQueries,
    queryHistoryEntries,
    pinnedTables,
    selectedSchemas,
    appStateEntries,
    idxConnectionsWorkspaceId,
    idxSavedQueriesConnectionId,
    idxQueryHistoryConnectionId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('connections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'connections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('saved_queries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'connections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('query_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'connections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pinned_tables', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'connections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('selected_schemas', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'connections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('app_state', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$WorkspacesTableCreateCompanionBuilder =
    WorkspacesCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WorkspacesTableUpdateCompanionBuilder =
    WorkspacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$WorkspacesTableReferences
    extends BaseReferences<_$QueryPodDatabase, $WorkspacesTable, WorkspaceRow> {
  $$WorkspacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ConnectionsTable, List<ConnectionRow>>
  _connectionsRefsTable(_$QueryPodDatabase db) => MultiTypedResultKey.fromTable(
    db.connections,
    aliasName: 'workspaces__id__connections__workspace_id',
  );

  $$ConnectionsTableProcessedTableManager get connectionsRefs {
    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_connectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkspacesTableFilterComposer
    extends Composer<_$QueryPodDatabase, $WorkspacesTable> {
  $$WorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> connectionsRefs(
    Expression<bool> Function($$ConnectionsTableFilterComposer f) f,
  ) {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableOrderingComposer
    extends Composer<_$QueryPodDatabase, $WorkspacesTable> {
  $$WorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableAnnotationComposer
    extends Composer<_$QueryPodDatabase, $WorkspacesTable> {
  $$WorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> connectionsRefs<T extends Object>(
    Expression<T> Function($$ConnectionsTableAnnotationComposer a) f,
  ) {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableTableManager
    extends
        RootTableManager<
          _$QueryPodDatabase,
          $WorkspacesTable,
          WorkspaceRow,
          $$WorkspacesTableFilterComposer,
          $$WorkspacesTableOrderingComposer,
          $$WorkspacesTableAnnotationComposer,
          $$WorkspacesTableCreateCompanionBuilder,
          $$WorkspacesTableUpdateCompanionBuilder,
          (WorkspaceRow, $$WorkspacesTableReferences),
          WorkspaceRow,
          PrefetchHooks Function({bool connectionsRefs})
        > {
  $$WorkspacesTableTableManager(_$QueryPodDatabase db, $WorkspacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkspacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (connectionsRefs) db.connections],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (connectionsRefs)
                    await $_getPrefetchedData<
                      WorkspaceRow,
                      $WorkspacesTable,
                      ConnectionRow
                    >(
                      currentTable: table,
                      referencedTable: $$WorkspacesTableReferences
                          ._connectionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkspacesTableReferences(
                            db,
                            table,
                            p0,
                          ).connectionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.workspaceId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$QueryPodDatabase,
      $WorkspacesTable,
      WorkspaceRow,
      $$WorkspacesTableFilterComposer,
      $$WorkspacesTableOrderingComposer,
      $$WorkspacesTableAnnotationComposer,
      $$WorkspacesTableCreateCompanionBuilder,
      $$WorkspacesTableUpdateCompanionBuilder,
      (WorkspaceRow, $$WorkspacesTableReferences),
      WorkspaceRow,
      PrefetchHooks Function({bool connectionsRefs})
    >;
typedef $$ConnectionsTableCreateCompanionBuilder =
    ConnectionsCompanion Function({
      required String id,
      required String workspaceId,
      required String name,
      required String host,
      required int port,
      required String user,
      required String database,
      required String connectionType,
      required bool useTls,
      Value<int> rowid,
    });
typedef $$ConnectionsTableUpdateCompanionBuilder =
    ConnectionsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> name,
      Value<String> host,
      Value<int> port,
      Value<String> user,
      Value<String> database,
      Value<String> connectionType,
      Value<bool> useTls,
      Value<int> rowid,
    });

final class $$ConnectionsTableReferences
    extends
        BaseReferences<_$QueryPodDatabase, $ConnectionsTable, ConnectionRow> {
  $$ConnectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$QueryPodDatabase db) =>
      db.workspaces.createAlias('connections__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SavedQueriesTable, List<SavedQueryRow>>
  _savedQueriesRefsTable(_$QueryPodDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.savedQueries,
        aliasName: 'connections__id__saved_queries__connection_id',
      );

  $$SavedQueriesTableProcessedTableManager get savedQueriesRefs {
    final manager = $$SavedQueriesTableTableManager(
      $_db,
      $_db.savedQueries,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_savedQueriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QueryHistoryEntriesTable, List<QueryHistoryRow>>
  _queryHistoryEntriesRefsTable(_$QueryPodDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.queryHistoryEntries,
        aliasName: 'connections__id__query_history__connection_id',
      );

  $$QueryHistoryEntriesTableProcessedTableManager get queryHistoryEntriesRefs {
    final manager = $$QueryHistoryEntriesTableTableManager(
      $_db,
      $_db.queryHistoryEntries,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _queryHistoryEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PinnedTablesTable, List<PinnedTableRow>>
  _pinnedTablesRefsTable(_$QueryPodDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.pinnedTables,
        aliasName: 'connections__id__pinned_tables__connection_id',
      );

  $$PinnedTablesTableProcessedTableManager get pinnedTablesRefs {
    final manager = $$PinnedTablesTableTableManager(
      $_db,
      $_db.pinnedTables,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pinnedTablesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SelectedSchemasTable, List<SelectedSchemaRow>>
  _selectedSchemasRefsTable(_$QueryPodDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.selectedSchemas,
        aliasName: 'connections__id__selected_schemas__connection_id',
      );

  $$SelectedSchemasTableProcessedTableManager get selectedSchemasRefs {
    final manager = $$SelectedSchemasTableTableManager(
      $_db,
      $_db.selectedSchemas,
    ).filter((f) => f.connectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _selectedSchemasRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AppStateEntriesTable, List<AppStateRow>>
  _appStateEntriesRefsTable(_$QueryPodDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.appStateEntries,
        aliasName: 'connections__id__app_state__selected_connection_id',
      );

  $$AppStateEntriesTableProcessedTableManager get appStateEntriesRefs {
    final manager =
        $$AppStateEntriesTableTableManager($_db, $_db.appStateEntries).filter(
          (f) =>
              f.selectedConnectionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _appStateEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConnectionsTableFilterComposer
    extends Composer<_$QueryPodDatabase, $ConnectionsTable> {
  $$ConnectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get user => $composableBuilder(
    column: $table.user,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get database => $composableBuilder(
    column: $table.database,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useTls => $composableBuilder(
    column: $table.useTls,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> savedQueriesRefs(
    Expression<bool> Function($$SavedQueriesTableFilterComposer f) f,
  ) {
    final $$SavedQueriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedQueries,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedQueriesTableFilterComposer(
            $db: $db,
            $table: $db.savedQueries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> queryHistoryEntriesRefs(
    Expression<bool> Function($$QueryHistoryEntriesTableFilterComposer f) f,
  ) {
    final $$QueryHistoryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queryHistoryEntries,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueryHistoryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.queryHistoryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pinnedTablesRefs(
    Expression<bool> Function($$PinnedTablesTableFilterComposer f) f,
  ) {
    final $$PinnedTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pinnedTables,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinnedTablesTableFilterComposer(
            $db: $db,
            $table: $db.pinnedTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> selectedSchemasRefs(
    Expression<bool> Function($$SelectedSchemasTableFilterComposer f) f,
  ) {
    final $$SelectedSchemasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.selectedSchemas,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SelectedSchemasTableFilterComposer(
            $db: $db,
            $table: $db.selectedSchemas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> appStateEntriesRefs(
    Expression<bool> Function($$AppStateEntriesTableFilterComposer f) f,
  ) {
    final $$AppStateEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appStateEntries,
      getReferencedColumn: (t) => t.selectedConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppStateEntriesTableFilterComposer(
            $db: $db,
            $table: $db.appStateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConnectionsTableOrderingComposer
    extends Composer<_$QueryPodDatabase, $ConnectionsTable> {
  $$ConnectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get user => $composableBuilder(
    column: $table.user,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get database => $composableBuilder(
    column: $table.database,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useTls => $composableBuilder(
    column: $table.useTls,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConnectionsTableAnnotationComposer
    extends Composer<_$QueryPodDatabase, $ConnectionsTable> {
  $$ConnectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get user =>
      $composableBuilder(column: $table.user, builder: (column) => column);

  GeneratedColumn<String> get database =>
      $composableBuilder(column: $table.database, builder: (column) => column);

  GeneratedColumn<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useTls =>
      $composableBuilder(column: $table.useTls, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> savedQueriesRefs<T extends Object>(
    Expression<T> Function($$SavedQueriesTableAnnotationComposer a) f,
  ) {
    final $$SavedQueriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedQueries,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedQueriesTableAnnotationComposer(
            $db: $db,
            $table: $db.savedQueries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> queryHistoryEntriesRefs<T extends Object>(
    Expression<T> Function($$QueryHistoryEntriesTableAnnotationComposer a) f,
  ) {
    final $$QueryHistoryEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.queryHistoryEntries,
          getReferencedColumn: (t) => t.connectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$QueryHistoryEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.queryHistoryEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> pinnedTablesRefs<T extends Object>(
    Expression<T> Function($$PinnedTablesTableAnnotationComposer a) f,
  ) {
    final $$PinnedTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pinnedTables,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinnedTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.pinnedTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> selectedSchemasRefs<T extends Object>(
    Expression<T> Function($$SelectedSchemasTableAnnotationComposer a) f,
  ) {
    final $$SelectedSchemasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.selectedSchemas,
      getReferencedColumn: (t) => t.connectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SelectedSchemasTableAnnotationComposer(
            $db: $db,
            $table: $db.selectedSchemas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> appStateEntriesRefs<T extends Object>(
    Expression<T> Function($$AppStateEntriesTableAnnotationComposer a) f,
  ) {
    final $$AppStateEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appStateEntries,
      getReferencedColumn: (t) => t.selectedConnectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppStateEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.appStateEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConnectionsTableTableManager
    extends
        RootTableManager<
          _$QueryPodDatabase,
          $ConnectionsTable,
          ConnectionRow,
          $$ConnectionsTableFilterComposer,
          $$ConnectionsTableOrderingComposer,
          $$ConnectionsTableAnnotationComposer,
          $$ConnectionsTableCreateCompanionBuilder,
          $$ConnectionsTableUpdateCompanionBuilder,
          (ConnectionRow, $$ConnectionsTableReferences),
          ConnectionRow,
          PrefetchHooks Function({
            bool workspaceId,
            bool savedQueriesRefs,
            bool queryHistoryEntriesRefs,
            bool pinnedTablesRefs,
            bool selectedSchemasRefs,
            bool appStateEntriesRefs,
          })
        > {
  $$ConnectionsTableTableManager(_$QueryPodDatabase db, $ConnectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> user = const Value.absent(),
                Value<String> database = const Value.absent(),
                Value<String> connectionType = const Value.absent(),
                Value<bool> useTls = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectionsCompanion(
                id: id,
                workspaceId: workspaceId,
                name: name,
                host: host,
                port: port,
                user: user,
                database: database,
                connectionType: connectionType,
                useTls: useTls,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String name,
                required String host,
                required int port,
                required String user,
                required String database,
                required String connectionType,
                required bool useTls,
                Value<int> rowid = const Value.absent(),
              }) => ConnectionsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                name: name,
                host: host,
                port: port,
                user: user,
                database: database,
                connectionType: connectionType,
                useTls: useTls,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConnectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                savedQueriesRefs = false,
                queryHistoryEntriesRefs = false,
                pinnedTablesRefs = false,
                selectedSchemasRefs = false,
                appStateEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (savedQueriesRefs) db.savedQueries,
                    if (queryHistoryEntriesRefs) db.queryHistoryEntries,
                    if (pinnedTablesRefs) db.pinnedTables,
                    if (selectedSchemasRefs) db.selectedSchemas,
                    if (appStateEntriesRefs) db.appStateEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable:
                                        $$ConnectionsTableReferences
                                            ._workspaceIdTable(db),
                                    referencedColumn:
                                        $$ConnectionsTableReferences
                                            ._workspaceIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (savedQueriesRefs)
                        await $_getPrefetchedData<
                          ConnectionRow,
                          $ConnectionsTable,
                          SavedQueryRow
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._savedQueriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).savedQueriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (queryHistoryEntriesRefs)
                        await $_getPrefetchedData<
                          ConnectionRow,
                          $ConnectionsTable,
                          QueryHistoryRow
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._queryHistoryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).queryHistoryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pinnedTablesRefs)
                        await $_getPrefetchedData<
                          ConnectionRow,
                          $ConnectionsTable,
                          PinnedTableRow
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._pinnedTablesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).pinnedTablesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (selectedSchemasRefs)
                        await $_getPrefetchedData<
                          ConnectionRow,
                          $ConnectionsTable,
                          SelectedSchemaRow
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._selectedSchemasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).selectedSchemasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.connectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (appStateEntriesRefs)
                        await $_getPrefetchedData<
                          ConnectionRow,
                          $ConnectionsTable,
                          AppStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$ConnectionsTableReferences
                              ._appStateEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConnectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).appStateEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.selectedConnectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$QueryPodDatabase,
      $ConnectionsTable,
      ConnectionRow,
      $$ConnectionsTableFilterComposer,
      $$ConnectionsTableOrderingComposer,
      $$ConnectionsTableAnnotationComposer,
      $$ConnectionsTableCreateCompanionBuilder,
      $$ConnectionsTableUpdateCompanionBuilder,
      (ConnectionRow, $$ConnectionsTableReferences),
      ConnectionRow,
      PrefetchHooks Function({
        bool workspaceId,
        bool savedQueriesRefs,
        bool queryHistoryEntriesRefs,
        bool pinnedTablesRefs,
        bool selectedSchemasRefs,
        bool appStateEntriesRefs,
      })
    >;
typedef $$SavedQueriesTableCreateCompanionBuilder =
    SavedQueriesCompanion Function({
      required String id,
      required String connectionId,
      required String title,
      required String sql,
      Value<String?> database,
      Value<String?> querySchema,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SavedQueriesTableUpdateCompanionBuilder =
    SavedQueriesCompanion Function({
      Value<String> id,
      Value<String> connectionId,
      Value<String> title,
      Value<String> sql,
      Value<String?> database,
      Value<String?> querySchema,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SavedQueriesTableReferences
    extends
        BaseReferences<_$QueryPodDatabase, $SavedQueriesTable, SavedQueryRow> {
  $$SavedQueriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionsTable _connectionIdTable(_$QueryPodDatabase db) => db
      .connections
      .createAlias('saved_queries__connection_id__connections__id');

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<String>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavedQueriesTableFilterComposer
    extends Composer<_$QueryPodDatabase, $SavedQueriesTable> {
  $$SavedQueriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sql => $composableBuilder(
    column: $table.sql,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get database => $composableBuilder(
    column: $table.database,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get querySchema => $composableBuilder(
    column: $table.querySchema,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedQueriesTableOrderingComposer
    extends Composer<_$QueryPodDatabase, $SavedQueriesTable> {
  $$SavedQueriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sql => $composableBuilder(
    column: $table.sql,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get database => $composableBuilder(
    column: $table.database,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get querySchema => $composableBuilder(
    column: $table.querySchema,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedQueriesTableAnnotationComposer
    extends Composer<_$QueryPodDatabase, $SavedQueriesTable> {
  $$SavedQueriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sql =>
      $composableBuilder(column: $table.sql, builder: (column) => column);

  GeneratedColumn<String> get database =>
      $composableBuilder(column: $table.database, builder: (column) => column);

  GeneratedColumn<String> get querySchema => $composableBuilder(
    column: $table.querySchema,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedQueriesTableTableManager
    extends
        RootTableManager<
          _$QueryPodDatabase,
          $SavedQueriesTable,
          SavedQueryRow,
          $$SavedQueriesTableFilterComposer,
          $$SavedQueriesTableOrderingComposer,
          $$SavedQueriesTableAnnotationComposer,
          $$SavedQueriesTableCreateCompanionBuilder,
          $$SavedQueriesTableUpdateCompanionBuilder,
          (SavedQueryRow, $$SavedQueriesTableReferences),
          SavedQueryRow,
          PrefetchHooks Function({bool connectionId})
        > {
  $$SavedQueriesTableTableManager(
    _$QueryPodDatabase db,
    $SavedQueriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedQueriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedQueriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedQueriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> connectionId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> sql = const Value.absent(),
                Value<String?> database = const Value.absent(),
                Value<String?> querySchema = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedQueriesCompanion(
                id: id,
                connectionId: connectionId,
                title: title,
                sql: sql,
                database: database,
                querySchema: querySchema,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String connectionId,
                required String title,
                required String sql,
                Value<String?> database = const Value.absent(),
                Value<String?> querySchema = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedQueriesCompanion.insert(
                id: id,
                connectionId: connectionId,
                title: title,
                sql: sql,
                database: database,
                querySchema: querySchema,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SavedQueriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable: $$SavedQueriesTableReferences
                                    ._connectionIdTable(db),
                                referencedColumn: $$SavedQueriesTableReferences
                                    ._connectionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SavedQueriesTableProcessedTableManager =
    ProcessedTableManager<
      _$QueryPodDatabase,
      $SavedQueriesTable,
      SavedQueryRow,
      $$SavedQueriesTableFilterComposer,
      $$SavedQueriesTableOrderingComposer,
      $$SavedQueriesTableAnnotationComposer,
      $$SavedQueriesTableCreateCompanionBuilder,
      $$SavedQueriesTableUpdateCompanionBuilder,
      (SavedQueryRow, $$SavedQueriesTableReferences),
      SavedQueryRow,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$QueryHistoryEntriesTableCreateCompanionBuilder =
    QueryHistoryEntriesCompanion Function({
      required String id,
      required String connectionId,
      required String sourceType,
      Value<String?> sourceId,
      required String sql,
      required int executionTimeMs,
      required String status,
      Value<String?> errorMessage,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$QueryHistoryEntriesTableUpdateCompanionBuilder =
    QueryHistoryEntriesCompanion Function({
      Value<String> id,
      Value<String> connectionId,
      Value<String> sourceType,
      Value<String?> sourceId,
      Value<String> sql,
      Value<int> executionTimeMs,
      Value<String> status,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$QueryHistoryEntriesTableReferences
    extends
        BaseReferences<
          _$QueryPodDatabase,
          $QueryHistoryEntriesTable,
          QueryHistoryRow
        > {
  $$QueryHistoryEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConnectionsTable _connectionIdTable(_$QueryPodDatabase db) => db
      .connections
      .createAlias('query_history__connection_id__connections__id');

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<String>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QueryHistoryEntriesTableFilterComposer
    extends Composer<_$QueryPodDatabase, $QueryHistoryEntriesTable> {
  $$QueryHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sql => $composableBuilder(
    column: $table.sql,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get executionTimeMs => $composableBuilder(
    column: $table.executionTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueryHistoryEntriesTableOrderingComposer
    extends Composer<_$QueryPodDatabase, $QueryHistoryEntriesTable> {
  $$QueryHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sql => $composableBuilder(
    column: $table.sql,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get executionTimeMs => $composableBuilder(
    column: $table.executionTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueryHistoryEntriesTableAnnotationComposer
    extends Composer<_$QueryPodDatabase, $QueryHistoryEntriesTable> {
  $$QueryHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sql =>
      $composableBuilder(column: $table.sql, builder: (column) => column);

  GeneratedColumn<int> get executionTimeMs => $composableBuilder(
    column: $table.executionTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueryHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$QueryPodDatabase,
          $QueryHistoryEntriesTable,
          QueryHistoryRow,
          $$QueryHistoryEntriesTableFilterComposer,
          $$QueryHistoryEntriesTableOrderingComposer,
          $$QueryHistoryEntriesTableAnnotationComposer,
          $$QueryHistoryEntriesTableCreateCompanionBuilder,
          $$QueryHistoryEntriesTableUpdateCompanionBuilder,
          (QueryHistoryRow, $$QueryHistoryEntriesTableReferences),
          QueryHistoryRow,
          PrefetchHooks Function({bool connectionId})
        > {
  $$QueryHistoryEntriesTableTableManager(
    _$QueryPodDatabase db,
    $QueryHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueryHistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueryHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QueryHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> connectionId = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> sql = const Value.absent(),
                Value<int> executionTimeMs = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueryHistoryEntriesCompanion(
                id: id,
                connectionId: connectionId,
                sourceType: sourceType,
                sourceId: sourceId,
                sql: sql,
                executionTimeMs: executionTimeMs,
                status: status,
                errorMessage: errorMessage,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String connectionId,
                required String sourceType,
                Value<String?> sourceId = const Value.absent(),
                required String sql,
                required int executionTimeMs,
                required String status,
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => QueryHistoryEntriesCompanion.insert(
                id: id,
                connectionId: connectionId,
                sourceType: sourceType,
                sourceId: sourceId,
                sql: sql,
                executionTimeMs: executionTimeMs,
                status: status,
                errorMessage: errorMessage,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QueryHistoryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable:
                                    $$QueryHistoryEntriesTableReferences
                                        ._connectionIdTable(db),
                                referencedColumn:
                                    $$QueryHistoryEntriesTableReferences
                                        ._connectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QueryHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$QueryPodDatabase,
      $QueryHistoryEntriesTable,
      QueryHistoryRow,
      $$QueryHistoryEntriesTableFilterComposer,
      $$QueryHistoryEntriesTableOrderingComposer,
      $$QueryHistoryEntriesTableAnnotationComposer,
      $$QueryHistoryEntriesTableCreateCompanionBuilder,
      $$QueryHistoryEntriesTableUpdateCompanionBuilder,
      (QueryHistoryRow, $$QueryHistoryEntriesTableReferences),
      QueryHistoryRow,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$PinnedTablesTableCreateCompanionBuilder =
    PinnedTablesCompanion Function({
      required String connectionId,
      required String database,
      Value<String> pgSchema,
      required String table,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$PinnedTablesTableUpdateCompanionBuilder =
    PinnedTablesCompanion Function({
      Value<String> connectionId,
      Value<String> database,
      Value<String> pgSchema,
      Value<String> table,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$PinnedTablesTableReferences
    extends
        BaseReferences<_$QueryPodDatabase, $PinnedTablesTable, PinnedTableRow> {
  $$PinnedTablesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionsTable _connectionIdTable(_$QueryPodDatabase db) => db
      .connections
      .createAlias('pinned_tables__connection_id__connections__id');

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<String>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PinnedTablesTableFilterComposer
    extends Composer<_$QueryPodDatabase, $PinnedTablesTable> {
  $$PinnedTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get database => $composableBuilder(
    column: $table.database,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pgSchema => $composableBuilder(
    column: $table.pgSchema,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get table => $composableBuilder(
    column: $table.table,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PinnedTablesTableOrderingComposer
    extends Composer<_$QueryPodDatabase, $PinnedTablesTable> {
  $$PinnedTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get database => $composableBuilder(
    column: $table.database,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pgSchema => $composableBuilder(
    column: $table.pgSchema,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get table => $composableBuilder(
    column: $table.table,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PinnedTablesTableAnnotationComposer
    extends Composer<_$QueryPodDatabase, $PinnedTablesTable> {
  $$PinnedTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get database =>
      $composableBuilder(column: $table.database, builder: (column) => column);

  GeneratedColumn<String> get pgSchema =>
      $composableBuilder(column: $table.pgSchema, builder: (column) => column);

  GeneratedColumn<String> get table =>
      $composableBuilder(column: $table.table, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PinnedTablesTableTableManager
    extends
        RootTableManager<
          _$QueryPodDatabase,
          $PinnedTablesTable,
          PinnedTableRow,
          $$PinnedTablesTableFilterComposer,
          $$PinnedTablesTableOrderingComposer,
          $$PinnedTablesTableAnnotationComposer,
          $$PinnedTablesTableCreateCompanionBuilder,
          $$PinnedTablesTableUpdateCompanionBuilder,
          (PinnedTableRow, $$PinnedTablesTableReferences),
          PinnedTableRow,
          PrefetchHooks Function({bool connectionId})
        > {
  $$PinnedTablesTableTableManager(
    _$QueryPodDatabase db,
    $PinnedTablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PinnedTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PinnedTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PinnedTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> connectionId = const Value.absent(),
                Value<String> database = const Value.absent(),
                Value<String> pgSchema = const Value.absent(),
                Value<String> table = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PinnedTablesCompanion(
                connectionId: connectionId,
                database: database,
                pgSchema: pgSchema,
                table: table,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String connectionId,
                required String database,
                Value<String> pgSchema = const Value.absent(),
                required String table,
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => PinnedTablesCompanion.insert(
                connectionId: connectionId,
                database: database,
                pgSchema: pgSchema,
                table: table,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PinnedTablesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable: $$PinnedTablesTableReferences
                                    ._connectionIdTable(db),
                                referencedColumn: $$PinnedTablesTableReferences
                                    ._connectionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PinnedTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$QueryPodDatabase,
      $PinnedTablesTable,
      PinnedTableRow,
      $$PinnedTablesTableFilterComposer,
      $$PinnedTablesTableOrderingComposer,
      $$PinnedTablesTableAnnotationComposer,
      $$PinnedTablesTableCreateCompanionBuilder,
      $$PinnedTablesTableUpdateCompanionBuilder,
      (PinnedTableRow, $$PinnedTablesTableReferences),
      PinnedTableRow,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$SelectedSchemasTableCreateCompanionBuilder =
    SelectedSchemasCompanion Function({
      required String connectionId,
      required String database,
      required String pgSchema,
      Value<int> rowid,
    });
typedef $$SelectedSchemasTableUpdateCompanionBuilder =
    SelectedSchemasCompanion Function({
      Value<String> connectionId,
      Value<String> database,
      Value<String> pgSchema,
      Value<int> rowid,
    });

final class $$SelectedSchemasTableReferences
    extends
        BaseReferences<
          _$QueryPodDatabase,
          $SelectedSchemasTable,
          SelectedSchemaRow
        > {
  $$SelectedSchemasTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConnectionsTable _connectionIdTable(_$QueryPodDatabase db) => db
      .connections
      .createAlias('selected_schemas__connection_id__connections__id');

  $$ConnectionsTableProcessedTableManager get connectionId {
    final $_column = $_itemColumn<String>('connection_id')!;

    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SelectedSchemasTableFilterComposer
    extends Composer<_$QueryPodDatabase, $SelectedSchemasTable> {
  $$SelectedSchemasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get database => $composableBuilder(
    column: $table.database,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pgSchema => $composableBuilder(
    column: $table.pgSchema,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get connectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SelectedSchemasTableOrderingComposer
    extends Composer<_$QueryPodDatabase, $SelectedSchemasTable> {
  $$SelectedSchemasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get database => $composableBuilder(
    column: $table.database,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pgSchema => $composableBuilder(
    column: $table.pgSchema,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get connectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SelectedSchemasTableAnnotationComposer
    extends Composer<_$QueryPodDatabase, $SelectedSchemasTable> {
  $$SelectedSchemasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get database =>
      $composableBuilder(column: $table.database, builder: (column) => column);

  GeneratedColumn<String> get pgSchema =>
      $composableBuilder(column: $table.pgSchema, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get connectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.connectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SelectedSchemasTableTableManager
    extends
        RootTableManager<
          _$QueryPodDatabase,
          $SelectedSchemasTable,
          SelectedSchemaRow,
          $$SelectedSchemasTableFilterComposer,
          $$SelectedSchemasTableOrderingComposer,
          $$SelectedSchemasTableAnnotationComposer,
          $$SelectedSchemasTableCreateCompanionBuilder,
          $$SelectedSchemasTableUpdateCompanionBuilder,
          (SelectedSchemaRow, $$SelectedSchemasTableReferences),
          SelectedSchemaRow,
          PrefetchHooks Function({bool connectionId})
        > {
  $$SelectedSchemasTableTableManager(
    _$QueryPodDatabase db,
    $SelectedSchemasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SelectedSchemasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SelectedSchemasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SelectedSchemasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> connectionId = const Value.absent(),
                Value<String> database = const Value.absent(),
                Value<String> pgSchema = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SelectedSchemasCompanion(
                connectionId: connectionId,
                database: database,
                pgSchema: pgSchema,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String connectionId,
                required String database,
                required String pgSchema,
                Value<int> rowid = const Value.absent(),
              }) => SelectedSchemasCompanion.insert(
                connectionId: connectionId,
                database: database,
                pgSchema: pgSchema,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SelectedSchemasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({connectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (connectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.connectionId,
                                referencedTable:
                                    $$SelectedSchemasTableReferences
                                        ._connectionIdTable(db),
                                referencedColumn:
                                    $$SelectedSchemasTableReferences
                                        ._connectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SelectedSchemasTableProcessedTableManager =
    ProcessedTableManager<
      _$QueryPodDatabase,
      $SelectedSchemasTable,
      SelectedSchemaRow,
      $$SelectedSchemasTableFilterComposer,
      $$SelectedSchemasTableOrderingComposer,
      $$SelectedSchemasTableAnnotationComposer,
      $$SelectedSchemasTableCreateCompanionBuilder,
      $$SelectedSchemasTableUpdateCompanionBuilder,
      (SelectedSchemaRow, $$SelectedSchemasTableReferences),
      SelectedSchemaRow,
      PrefetchHooks Function({bool connectionId})
    >;
typedef $$AppStateEntriesTableCreateCompanionBuilder =
    AppStateEntriesCompanion Function({
      Value<int> id,
      Value<String?> selectedConnectionId,
      Value<int> zoomLevel,
    });
typedef $$AppStateEntriesTableUpdateCompanionBuilder =
    AppStateEntriesCompanion Function({
      Value<int> id,
      Value<String?> selectedConnectionId,
      Value<int> zoomLevel,
    });

final class $$AppStateEntriesTableReferences
    extends
        BaseReferences<_$QueryPodDatabase, $AppStateEntriesTable, AppStateRow> {
  $$AppStateEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConnectionsTable _selectedConnectionIdTable(_$QueryPodDatabase db) =>
      db.connections.createAlias(
        'app_state__selected_connection_id__connections__id',
      );

  $$ConnectionsTableProcessedTableManager? get selectedConnectionId {
    final $_column = $_itemColumn<String>('selected_connection_id');
    if ($_column == null) return null;
    final manager = $$ConnectionsTableTableManager(
      $_db,
      $_db.connections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _selectedConnectionIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AppStateEntriesTableFilterComposer
    extends Composer<_$QueryPodDatabase, $AppStateEntriesTable> {
  $$AppStateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zoomLevel => $composableBuilder(
    column: $table.zoomLevel,
    builder: (column) => ColumnFilters(column),
  );

  $$ConnectionsTableFilterComposer get selectedConnectionId {
    final $$ConnectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.selectedConnectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableFilterComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppStateEntriesTableOrderingComposer
    extends Composer<_$QueryPodDatabase, $AppStateEntriesTable> {
  $$AppStateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zoomLevel => $composableBuilder(
    column: $table.zoomLevel,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConnectionsTableOrderingComposer get selectedConnectionId {
    final $$ConnectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.selectedConnectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableOrderingComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppStateEntriesTableAnnotationComposer
    extends Composer<_$QueryPodDatabase, $AppStateEntriesTable> {
  $$AppStateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get zoomLevel =>
      $composableBuilder(column: $table.zoomLevel, builder: (column) => column);

  $$ConnectionsTableAnnotationComposer get selectedConnectionId {
    final $$ConnectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.selectedConnectionId,
      referencedTable: $db.connections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.connections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppStateEntriesTableTableManager
    extends
        RootTableManager<
          _$QueryPodDatabase,
          $AppStateEntriesTable,
          AppStateRow,
          $$AppStateEntriesTableFilterComposer,
          $$AppStateEntriesTableOrderingComposer,
          $$AppStateEntriesTableAnnotationComposer,
          $$AppStateEntriesTableCreateCompanionBuilder,
          $$AppStateEntriesTableUpdateCompanionBuilder,
          (AppStateRow, $$AppStateEntriesTableReferences),
          AppStateRow,
          PrefetchHooks Function({bool selectedConnectionId})
        > {
  $$AppStateEntriesTableTableManager(
    _$QueryPodDatabase db,
    $AppStateEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppStateEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppStateEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppStateEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> selectedConnectionId = const Value.absent(),
                Value<int> zoomLevel = const Value.absent(),
              }) => AppStateEntriesCompanion(
                id: id,
                selectedConnectionId: selectedConnectionId,
                zoomLevel: zoomLevel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> selectedConnectionId = const Value.absent(),
                Value<int> zoomLevel = const Value.absent(),
              }) => AppStateEntriesCompanion.insert(
                id: id,
                selectedConnectionId: selectedConnectionId,
                zoomLevel: zoomLevel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AppStateEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({selectedConnectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (selectedConnectionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.selectedConnectionId,
                                referencedTable:
                                    $$AppStateEntriesTableReferences
                                        ._selectedConnectionIdTable(db),
                                referencedColumn:
                                    $$AppStateEntriesTableReferences
                                        ._selectedConnectionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AppStateEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$QueryPodDatabase,
      $AppStateEntriesTable,
      AppStateRow,
      $$AppStateEntriesTableFilterComposer,
      $$AppStateEntriesTableOrderingComposer,
      $$AppStateEntriesTableAnnotationComposer,
      $$AppStateEntriesTableCreateCompanionBuilder,
      $$AppStateEntriesTableUpdateCompanionBuilder,
      (AppStateRow, $$AppStateEntriesTableReferences),
      AppStateRow,
      PrefetchHooks Function({bool selectedConnectionId})
    >;

class $QueryPodDatabaseManager {
  final _$QueryPodDatabase _db;
  $QueryPodDatabaseManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$ConnectionsTableTableManager get connections =>
      $$ConnectionsTableTableManager(_db, _db.connections);
  $$SavedQueriesTableTableManager get savedQueries =>
      $$SavedQueriesTableTableManager(_db, _db.savedQueries);
  $$QueryHistoryEntriesTableTableManager get queryHistoryEntries =>
      $$QueryHistoryEntriesTableTableManager(_db, _db.queryHistoryEntries);
  $$PinnedTablesTableTableManager get pinnedTables =>
      $$PinnedTablesTableTableManager(_db, _db.pinnedTables);
  $$SelectedSchemasTableTableManager get selectedSchemas =>
      $$SelectedSchemasTableTableManager(_db, _db.selectedSchemas);
  $$AppStateEntriesTableTableManager get appStateEntries =>
      $$AppStateEntriesTableTableManager(_db, _db.appStateEntries);
}
