## How to reproduce the random test fail

1. git checkout random_fail

2. bundle install

3. cd activerecord

4. rake db:postgresql:build

5. rake test:postgresql

6. you would probably see other failure patterns with rake db:mysql:build => rake test:mysql2
