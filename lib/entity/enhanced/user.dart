part of entities;

class User extends Entity<String> {
  User.empty ();
  User ({String email, String name, int code}) :    
    _email = email, _name = name, _code = code;
  factory User.fromMap (Map<String, dynamic> map) {
    return new User(email: map['email'], name: map['name'], code: map['code']);
  }
  
  String _email;
  String _name;
  int _code;
  
  List asArray () => [_email, _name, _code];
  
  bool _validate (Persistable persistable, value) => persistable.validate(value);
  
  Symbol get idFieldName => _SYMBOL_EMAIL;
  
  String get email => _email;
  String get name => _name;
  int get code => _code;
  int get hashCode {
    final int p = 37;
    int hash = 1;
    hash = p * hash + _email.hashCode;
    hash = p * hash + _name.hashCode;
    hash = p * hash + _code.hashCode;
    return hash;
  }
  
  set email (String email) {
    if (_PERSISTABLE_EMAIL.validate(email)) {
      _email = email;
      propertyChanged(_SYMBOL_EMAIL);
    } else {
      throw new ArgumentError ('email is not valid');
    }
  }
  set name (String name) {
    if (_PERSISTABLE_NAME.validate(name)) {
      _name = name;
      propertyChanged(_SYMBOL_NAME);
    } else {
      throw new ArgumentError ('name is not valid');
    }
  }
  set code (int code) {
    if (_PERSISTABLE_CODE.validate(code)) {
      _code = code;
      propertyChanged(_SYMBOL_CODE);
    } else {
      throw new ArgumentError ('code is not valid');
    }
  }
  bool operator == (User e) => e.email == _email && e.name == _name && e.code == _code;
  static const Symbol _SYMBOL_EMAIL = const Symbol ('email'), _SYMBOL_NAME = const Symbol ('name'), _SYMBOL_CODE = const Symbol ('code');
  static const Persistable _PERSISTABLE_EMAIL = const StringPersistable (name: 'email'), _PERSISTABLE_NAME = const StringPersistable (), _PERSISTABLE_CODE = const IntPersistable ();
}
  