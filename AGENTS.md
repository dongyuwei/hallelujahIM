# AGENTS.md

## After any code change

Always run these commands in order:

```bash
sh format-code.sh
sh unit-tests.sh
bash build.sh
```

All three must pass before committing.

## comments
代码应该只保留必要的注释（应该尽可能精简，简明扼要），非必要的一律删除。

## notification
If any task of current session need user confirmation, call system cmd say: `say 'please confirm'`.

Once all tasks of current session finished, call system cmd say: `say 'task finished'`.

## commit message
commit message 应该简明扼要，不要太啰嗦。

## db design
db schema设计要充分考虑index，建好索引。
