# PyCrypto

Web + Crypto(not) challenge.

We are given a flask app, with the '/flag' route giving flag but only to localhost visiters.
Glancing over the code (bad decision) we find that there is some AES crypto happening when you do `/register` and `/login`.

There is a `/ticket` route which has a lot of CSP rules in it but allow script-inline.
This route takes a encrypted paramter and check if the user AES key matches its AES key and returns the decrypted contents passing it through `markdown2.markdown(res,safe_mode=True)` to prevent an injection.

There is also a `/submit` route which opens a headless browser and visits your link if the hostname matches the webservice host `76.74.170.201`

Now the attack plan became clear

1. Break AES
2. `markdown2.markdown == 2.3.8` has a known vulnerability, use it to bypass html injection.
3. fetch('/flag') and send it your server

Pretty straightforward.

The AES key had a length of 32
This was the encryption function

```
def encrypt(plaintext):
    plaintext = pad(plaintext)
    iv = pad("")
    ciphertext = ""
    for i in range(0, len(plaintext), BLOCK_SIZE):
        iv = xor(aes.encrypt(plaintext[i:i+BLOCK_SIZE]),iv)
        ciphertext += iv
```

We can easily break AES byte by byte by with different usernames.
```
def getBlock(candidate):
    register(candidate)
    result = unhexlify(getCipher(candidate))
    iv1 = result[:32]
    return iv1

def cracker():
    key = ''
    for i in range(len(key)+1, 32):
        candidate = ('a'*(32 - i))
        ref = getBlock(candidate)
        for p in string.printable:
            try:
                candidate = ('a'*(32 - i) + key) + p
                result = getBlock(candidate)
                if result == ref:
                    key += p
                    print("Match Found!!!", key)
                    break
            except Exception as e:
                print("Error Occured!", e)
    return key
```

Took its time and gave out the key `ASIS2020_W3bcrypt_ChAlLeNg3!@#%^`

Then using the python-markdown2 vulnerability along with scripts-inline csp allowed us to get XSS.
http://76.74.170.201:8080/ticket?msg=1d1758c42e3d973ad815770ad433bdf588d93bc5a40a7c2227879ab1ccbcf5c0af642137d577226fff5dc9dcaec9027b4a731b7c7a87ce3539a5d0c9c41a15c47b10641cd4113e84692f657d877aa04f29ca8d8031f4bea7886b0a3b380da4d0eb9912dbc75f8bfc004b84e24079894387df5ec1f7c1ccc1fa6470491314d60b&key=ASIS2020_W3bcrypt_ChAlLeNg3!%40%23%25^

This is when we came across the line that I just glanced over in the `/ticket` route

```
res_key = request.args.get("key")
if res_key == key and request.remote_addr != '127.0.0.1':        
```
**remote_addr != '127.0.0.1' This page will not load locally. WTF !**

At this point I started looking at Flask source code understanding how it gets the remote_addr value but no luck with any bypasses there.
It would not be as simple as just setting `X-Forwarded-For` header.

So now back to analysing the code again.

This host check was very suspicious

```
host = urlparse(url).netloc
try:
    host = host[:host.index(':')]
except:
    pass
```

This is definitely not the standard way to do this.
This could easily be bypassed with this url `http://76.74.170.201:@attacker.com/`

The `urlparse(url).netloc` will result in `76.74.170.201:@attacker.com` and then `host[:host.index(':')]` will give out `76.74.170.201`.
But opening it in a browser it will open attacker.com

At this point we can run javascript on the server. 
CORS prevented us from doing a simple `fetch('http://localhost:8080/flag)` we needed to be on the Same-Origin.

This made me think of DNS-Rebinding attack. I'll open my domain on the headless browser, rebind it to `127.0.0.1` after it has opened and just fetch the flag.

```
driver = webdriver.Chrome(chrome_options=options, executable_path='/usr/bin/chromedriver')
driver.implicitly_wait(30)
```

On first look this seemed to cause an issue, implicitly_wait(30) will instruct the browser to wait MAX 30 sec to load the DOM.
And executing DNS Rebinding attack should take over 60 seconds atleast ( assuming the browser uses a minimum DNS TTL of 30 seconds ).

I created a sleeping image endpoint to test the 30 second timeout. 

```
app.get("/backend/hang.png", function(req, res) {
    child_process.execSync("sleep 100");
    res.status(200).send();
});

```

To my suprise the 30 second timeout had no affect and I could keep the browser hanging as long as I needed.
But again to my suprise this was not needed.

I used this tool https://github.com/nccgroup/singularity/ to attack the challenge.

This has a technique called `multiple-answers` where the DNS server would send both the server address and the local ip in a single dns query.
Browser will always prefer the remote server, but once the initial attack page has been loaded it will ip-block the client  therefore forcing the browser to
use the other resolved address i.e `127.0.0.1`

The whole DNS rebinding process took less than 8-10 seconds. Although it took me 3-4 tries before DNS successfully rebinded and got the flag.

ASIS{Y0U_R3binded_DN5_f0r_SSRF}

P.S @teranq from the team justCatTheFish got bored and found a bypass for the 2.3.8 markdown fix. https://github.com/trentm/python-markdown2/issues/362



Follow me: https://twitter.com/abcdsh_/


