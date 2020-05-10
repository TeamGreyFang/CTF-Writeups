
# Environmental Issues

We were given 4 files

**issues.txt** - Text file, nothing interesting

**config.json** - Contained placeholders for 4 flags

**challenge.py** - 

This script asks us for a arrays of `[key , value , arg ]`

For each [key,value,arg], it generates a random flag and writes it to a temporary file and invokes a bash script `script.sh` loaded in nsjail where we control 2 parameters.

We are allowed to set 1 environment variable specified by `key=value` and one argument per script.sh invocation

Our goal is to read this flag by modifying the inputs to the script.
Now the limitation here is we are not allowed to use one enviorment variable more than once and we need 10,13,15 unique solutions to get flags 1,2 and 3

**script.sh** - 

```
set -x
if ! test -z "$USE_SED"
then
    echo "Sedsss"
    line="$(sed -n "/${1:?Missing arg1: name}/p" issues.txt)"
else
    line="$(grep "${1:?Missing arg1: name}" < issues.txt)"
fi
echo "$line"

silent() { "$@" &>/dev/null; return "$?"; }

quiet() { bash -c 'for fd in /proc/$$/fd/*
                   do eval "exec ${fd##*/}>&-"
                   done; "$@" &> /dev/null' bash "$@"; }

if ! silent hash imaginary
then
    silent imaginary
    quiet cat flag
fi
```

If the `USE_SED` variable is present it executes sed , otherwise it executes grep with user supplied argument.

`silent hash imaginary` executes hash command, redirects stdout to /dev/null returns the exit code

`quiet cat flag` - The quiet function iterates over each file descriptor and closes them. Further it executes cat flag and redirects stdout to /dev/null.


**Solution**

Our goal was to read the file /flag to stdout or stderr either by code execution or just a file read.

**#1**

We first started with the 'sed' command.
Looking at https://gtfobins.github.io/gtfobins/sed/ , we can see that we can execute commands using `sed -n '1e id' /etc/hosts`
However our input was wrapped inside `/(arg)/p` so modifying the arg to `Habitat/p;1e cat flag;#` gave us one solution. `;` allowed us to use multiple sed commands and `#` bypassed the last `/p`.

So now we had code execution, but inside the jail where everything but `/dev` was mapped RO and would not survive another restart.
So we quickly fiddled around with `/dev` trying to link `/dev/stdout` to `/dev/null`, however this too did not survive a restart.

**#2-9**

After endless searching about bash and exploring for special enviorment variables we came across ShellShock.

Bash previously allowed function declaration using simple enviorment variables. Yes.
https://unix.stackexchange.com/questions/233091/bash-functions-in-shell-variables

To declare a function simply set `foo='() { echo "Inside function"; }'` Now you can call `bash -c 'foo'`

This was pre-2016. After the shellshock vulnerability, the feature was removed :/

However if you exported a function using `export -f` you can see bash still stores the function in enviorment variable but with a different syntax
`BASH_FUNC_foo%% = () { echo "Inside function"; }`

So I did a quick test 
```
[
      "BASH_FUNC_foo%%",
      "() {  cat flag\n}",
      "X"
]
```
and add a call to foo in script and ran the script. It worked.

So now the plan was to override the function calls in the script.
`set , test , grep , echo , eval , exec , bash , return`

Now that is 8 overrides + 1 from the SED call, we were one away from a flag.

**#10**

Now hash did not work because stdout was redirected to null.
So we did this.

```
[
      "BASH_FUNC_hash%%",
      "() {  function return() { cat flag; } \n}",
      "X"
]
```

Calling hash will now override return

So we got 10 and **1 flag**

Now we needed 3 more for one more flag.

**#11**

The man page for grep listed a environment variable `GREP_OPTIONS` which allows us to set grep agruments through environment variable.
So to execute `grep -f flag --include=flag` using

```
[
      "GREP_OPTIONS",
      "-fflag --include=flag",
      "-r"
]

```

The solution `grep '-rfflag'` worked, but it timedout searching all directories recursively inside the jail.


We could not get any further, however the other four bypasses were
1. Override `cat`
2. Bash environment variables `PS4` `BASH_ENV`
3. The most difficult one to figure out was overriding `_command_not_found_handle`

P.S There was a uninteded solution by Bushwhackers `[["X", "Y", "-Irf/flag"]]` which worked everytime


