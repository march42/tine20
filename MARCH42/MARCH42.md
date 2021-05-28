# march42 addition to Tine2.0 Community Edition

https://conventionalcommits.org/
```COMMIT
feature(Tinebase): add redis server authentication

Added auth to redis configuration
Added global redis configuration
Fixed default redis configuration created by setup.php

Closes #6618 (#13378)
Closes #6434 (#13000)
```

## redis-auth

Configurable authentication at redis server.
Add auth to redis sub section of config.inc.php

### config.inc.php

```PHP
<?php
return array (
  /* +++ whatever configuration value */
  'redis' => array ( // global REDIS configuration (should be default for all usage)
    'host' => 'localhost',
    'port' => 6379,
    'pass' => 'sEcReTaUtHkEy',
  ),
  /* +++ whatever configuration value */
  'caching' => array (
    'active' => true,
    'backend' => 'Redis',
    'redis' => array ( // REDIS configuration for caching, will overwrite the global configuration
      'host' => 'redis-server-for-caching',
      'port' => 6379,
      'auth' => 'sEcReTaUtHkEy for caching redis',
    ),
  ),
  /* +++ whatever configuration value */
  'actionqueue' => array (
    'active' => true,
    'backend' => 'Redis',
    'host' => 'localhost', // ? wrong specification
    'port' => 6379, // ? wrong specification
    'redis' => array ( // REDIS configuration for actionqueue, will overwrite the global configuration
      'host' => 'redis-server-for-actionqueue',
      'port' => 6379,
      'auth' => 'sEcReTaUtHkEy for actionqueue redis',
    ),
  ),
  /* +++ whatever configuration value */
  'session' => array (
    'backend' => 'Redis',
    'host' => 'localhost', // ? wrong specification
    'port' => 6379, // ? wrong specification
    'redis' => array ( // REDIS configuration for session, will overwrite the global configuration
      'host' => 'redis-server-for-session',
      'port' => 6379,
      'auth' => 'sEcReTaUtHkEy for session redis',
    ),
  ),
  /* +++ whatever configuration value */
);
?>
```

#### auth array and string

specifying auth __user__name and __pass__word

```PHP
  'redis' => array (
    'host' => 'localhost',
    'port' => 6379,
    'user' => 'auth username',
    'pass' => 'sEcReTaUtHkEy for auth user',
  ),
```

Missing or empty __user__ field will be ignored for password only authentication.
Password can be specified in __auth__ field. This will be saved as __pass__ when modifying config.

```PHP
  'redis' => array (
    'host' => 'localhost',
    'port' => 6379,
    'auth' => 'sEcReTaUtHkEy for auth',
  ),
```

#### simple connection path string (like session.save_path in php.ini)

```INI
session.save_path = "tcp://host1:6379?weight=1, tcp://host2:6379?weight=2&timeout=2.5, tcp://host3:6379?weight=2&read_timeout=2.5"
session.save_path = "unix:///var/run/redis/redis.sock?persistent=1&weight=1&database=0"
```

- [ ] _tcp_ connection **scheme**
- [ ] _tls_ connection scheme
- [ ] **host** for tcp connection
- [ ] **port** for tcp connection
- [ ] _unix_ connection scheme
- [ ] **socket** path for unix connection
- [ ] use **persistent** connection
- [ ] connection **weight**
- [ ] connection **timeout**
- [ ] connection **auth** password only authentication
- [ ] connection **user** for authentication
- [ ] connection **pass** for authentication
- [ ] connection **prefix**
- [ ] connection **database**

The configuration parameters are explained at [phpredis GitHub](https://github.com/phpredis/phpredis#php-session-handler) for php.ini.

#### value processing, configuration setting priorisation

- [ ] user=>'';pass=>[REDIS_AUTH] if auth is string
- [ ] user=>[REDIS_AUTH]->[REDIS_AUTH_USER];pass=>[REDIS_AUTH]->[REDIS_AUTH_PASS] if auth is array

1. use values from /(caching/actionqueue/session)/_redis_/
1. use global values from /_redis_/
1. use values from /(caching/actionqueue/session)/ as last resort (see Issue #6434)

### tine20/Tinebase/Config.php

Definition of constants for keynames.

- [x] const REDIS
- [x] const REDIS_HOST
- [x] const REDIS_PORT
- [x] const REDIS_AUTH
- [x] const REDIS_AUTH_USER
- [x] const REDIS_AUTH_PASS
- [x] const REDIS_SCHEME
- [x] const REDIS_SCHEME_TCP
- [x] const REDIS_SCHEME_TLS
- [x] const REDIS_SCHEME_UNIX
- [x] const REDIS_SOCKET
- [x] const REDIS_PERSISTENT
- [x] const REDIS_WEIGHT
- [x] const REDIS_TIMEOUT
- [x] const REDIS_PREFIX
- [x] const REDIS_DATABASE

It would be nice to separate REDIS configuration structure and use a template for the declaration.

- [x] global redis configuration structure
- [ ] static $_properties
- [ ] CACHE redis configuration structure
- [ ] SESSION redis configuration structure
- [ ] ACTIONQUEUE redis configuration structure
- [ ] property REDIS_SCHEME should be ComboBox

### tests/tine20/Tinebase/ControllerTest.php

### tests/tine20/Tinebase/CacheTest.php

### tests/tine20/Tinebase/Lock/UnitTestFix.php

### tests/tine20/Calendar/performanceTests.php

### tine20/Tinebase/Session/Abstract.php

- [ ] find calls to function getConfiguredSessionBackendType()
- [ ] ucfirst(ini_get('session.save_handler'))
- [ ] line 288++ redis configuration and start

### tine20/Tinebase/Core.php

- [ ] check function setupCache
- [ ] setupCache $backendOptions array
- [ ] prepare function setupCache to use Tinebase_Config::getConfiguredRedisOptions

### tine20/Tinebase/Config/Abstract.php

- [x] function getConfiguredRedisOptions
- [x] fix getConfiguredRedisOptions - needs correct loading of config and Tinebase/Config/Struct
- [ ] getConfiguredRedisOptions - last resort fallback PHP.INI/session.safe_handler,save_path

### tine20/Tinebase/Lock.php

### tine20/Tinebase/RedisConfig.php

- [ ] move function getConfiguredRedisOptions from Tinebase/Config.php

### tine20/Tinebase/Cache/PerRequest.php

### tine20/Tinebase/Redis/Queue.php

```PHP
		// public function __construct($additionalConfig = array())
        $config = Tinebase_Config::getInstance()->get('actionqueue', NULL);
        
        if ($config === NULL && $config->adapter !== 'Redis') {
            throw new Tinebase_Exception('No redis config found!');
        } else {
            $this->_config = array_merge($this->_config, $config->toArray(), $additionalConfig);
        }
        
        $this->_redis = new Redis;
        $this->_redis->connect($this->_config['host'], $this->_config['port'], $this->_config['timeout']);
		$this->_redis->auth($this->_config['auth']);
```

- [x] call auth after connect, if auth configured
- [ ] check auth configuration to take string or array (maybe check auth function in Redis class)
- [ ] fallback to /redis configuration, if /actionqueue/redis unset
- [ ] check /actionqueue configuration, to take redis configuration array besides host/port/auth string - seems to be Issue #6434
- [ ] rework configuration processing

### tine20/Setup/Controller.php

- [ ] function checkConfigCaching()
- [ ] function _checkRedisConnect()

### tine20/Setup/js/ConfigManagerPanel.js

- [ ] combo session_backend, onChangeSessionBackend
- [ ] combo caching_backend, onChangeCacheBackend
- [ ] combo actionqueue_backend, onChangeQueueBackend

- [ ] combo redis_scheme (redisSchemeCombo)
- [ ] onChangeRedisScheme

### tine20/Tinebase/js/widgets/form/ConfigPanel.js

- [ ] getFormItems
- [ ] add 'setup-redis-group' to getFormItems
- [ ] onSaveConfig
- [ ] form2config
- [ ] config2form
- [ ] changeCard

### done & still To-Do

- [x] double check caching configuration for correct specification of redis parameters
- [ ] double check actionqueue configuration for correct specification of redis parameters
- [ ] double check session configuration for correct specification of redis parameters
- [ ] double check setup.php configuration
- [x] add auth call to redis class
- [x] add global configuration for redis server
- [x] add auth parameter to caching configuration
- [ ] rework redis auth configuration for user/pass array
- [ ] add auth parameter to actionqueue configuration
- [ ] add auth parameter to session configuration
- [ ] rework redis configurations to take global and individual configuration
- [ ] add configuration to setup.php
- [ ] rework redis configurations to take auth as string and array
- [ ] rework redis configurations to take simple setting (like session.save_path in php.ini)
- [ ] check and rework configuration redis processing
