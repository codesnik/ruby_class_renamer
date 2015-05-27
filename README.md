Naive ruby/rails refactoring tool

git mv many ruby files at once according to a refactor plan.
rename, add/remove namespaces(modules), indent/outindent accordingly,
replace constants globally on all the project afterwards.

Usage:

make a YAML file like this:

```yaml
---
-
  from: app/models/foo.rb
  to: app/services/subname/foo.rb
-
  from: app/models/bar.rb
  to: app/processes/damns/not_given.rb
  from_class: BAR
  to_class Damns::NotGiven
...
```

or simply
```yaml
---
app/models/foo.rb: app/services/subname/foo.rb
app/models/bar.rb: app/processes/damns/not_given.rb
...
```

then

```bash
  cd my_project
  /path/to/ruby_class_renamer.rb plan.yml
```
