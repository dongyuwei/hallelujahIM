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
Code should only keep necessary comments (should be as concise as possible, brief and to the point), and delete all non-essential ones.

## notification
If any task of current session need user confirmation, call system cmd say: `say 'please confirm'`.

Once all tasks of current session finished, call system cmd say: `say 'task finished'`. 

Remind the user that when testing manually, it is best to restart a new textEdit.app to test, because in the existing app the input method may not be activated correctly.

## commit message
commit message should be concise and to the point, not too wordy.

## db design
db schema design should fully consider indexes, and build indexes well.
