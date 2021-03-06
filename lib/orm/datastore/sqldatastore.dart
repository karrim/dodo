part of orm;

class SqlDataStore<E extends Entity> implements DataStore<E> {
  
  final Map<Symbol, Query> _dels = new Map<Symbol, Query> (), _gets = new Map<Symbol, Query> (),
      _puts = new Map<Symbol, Query> (), _upds = new Map<Symbol, Query> ();
  final ConnectionPool pool;
  
  SqlDataStore(this.pool);
  
  void close () {
    pool.close();
  }
  
  Future delete (E e) {
    Completer c = new Completer ();
    InstanceMirror mirror = reflect (e);
    Symbol id = e.idFieldName;
    
    Symbol name = mirror.type.qualifiedName;
    bool newQuery = false;
    Future<Query> q;
    if (_dels.containsKey(name)) {
      q = new Future.value(_dels[name]);
    } else {
      newQuery = true;
      q = pool
          .prepare('DELETE FROM ${e.runtimeType} WHERE ${MirrorSystem.getName(id)} = ?');
    }
    q.then((query) {
      if (newQuery) {
        _dels[mirror.type.qualifiedName] = query;
      }
      return query.execute([mirror.getField(id).reflectee]);
    }).then((Results results) {
      c.complete();
    });
    return c.future;
  }
  
  Future<Optional<E>> get (E e) {
    Completer<Optional<E>> c = new Completer<Optional<E>> ();
    InstanceMirror mirror = reflect (e);
    Symbol id = e.idFieldName;
    
    bool newQuery = false;
    Symbol name = mirror.type.qualifiedName;
    Future<Query> q;
    if (_gets.containsKey(name)) {
      q = new Future.value(_gets[name]);
    } else {
      newQuery = true;
      q = pool
          .prepare('SELECT * FROM ${e.runtimeType} WHERE ${MirrorSystem.getName(id)} = ? LIMIT 1');
    }
    q.then((query) {
      if (newQuery) {
        _gets[mirror.type.qualifiedName] = query;
      }
      return query.execute([mirror.getField(id).reflectee]);
    }).then((Results results) {
      results.first.then((Row result) {
        int i = 0;
        results.fields.forEach((field) {
          mirror.setField(new Symbol ('${field.name}'), result[i]);
          i++;
        });
        c.complete(new Optional<E>(e));
      }).catchError((e) => c.complete(new Optional<E>.absent()),
          test: (e) => e is StateError);
    });
    return c.future;
  }
  
  Future put (E e) {
    Completer c = new Completer ();
    pool.startTransaction(consistent: true).then((transaction) {
      InstanceMirror mirror = reflect (e);
      Symbol name = mirror.type.qualifiedName;
      Future<Query> q;
      List values = e.asArray();
      
      bool newQuery = false;
      if (_puts.containsKey(name)) {
        q = new Future.value(_puts[name]);
      } else {
        newQuery = true;
        var qms = new StringBuffer ();
        for (int i = 0; i < values.length; i++) {
          qms.write('?, ');
        }
        q = transaction
            .prepare('INSERT INTO ${e.runtimeType} VALUES (${qms.toString().substring(0, qms.length - 2)})');
      }
      q.then((query) {
        if (newQuery) {
          _puts[mirror.type.qualifiedName] = query;
        }
        query.execute(values).then((results) {
          //results will be empty, but auto-increment columns will be reported
          transaction.commit().whenComplete(() => c.complete());
        });
      });
    });
    return c.future;
  }
  
  Future update (E e, [List<Symbol> symbols = null]) {
    Completer c = new Completer ();
    
    pool.startTransaction(consistent: true).then((transaction) {
      InstanceMirror mirror = reflect (e);
      Symbol id = e.idFieldName;
      Symbol name = mirror.type.qualifiedName;
      Future<Query> q;
      List values = [];
      
      bool newQuery = false;
      if (_upds.containsKey(name)) {
        q = new Future.value(_upds[name]);
      } else {
        StringBuffer sets = new StringBuffer ();
        
        if (symbols == null) {
          //TODO
        } else {
          symbols.forEach((name) {
            sets.write('${MirrorSystem.getName(name)} = ?, ');
            values.add(mirror.getField(name).reflectee);
          });
        }
        q = transaction
            .prepare('UPDATE ${e.runtimeType} SET ${sets.toString().substring(0, sets.length - 2)} WHERE ${MirrorSystem.getName(id)} = ?');
      }
      
      q.then((query) {
        values.add(mirror.getField(id).reflectee);
        return query.execute(values);
      }).then((_) {
        c.complete();
        transaction.commit();
      });
    });
    
    return c.future;
  }
}