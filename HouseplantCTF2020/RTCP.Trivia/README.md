
# RTCP Trivia

We are given a Trivia App APK with the description saying we need to answer 1000 question correctly.

Starting with decompiling the app
`jadx -d source/ client.apk` 

We get one package `wtf.riceteacatpanda.quiz` with 4 classes `MainActivity Game LoggedIn Flag`
There was nothing interesting in the `Flag.java` file, it recieved the flag via intent and displayed it.

The interesting ones were `MainActivity.java` and `Game.java`.
Now jadx wasn't able to decompile `MainActivity.java` properly, neither was JEB.(Another decompiler I tried, the `a()` method was missing in all of them)

So I did `jadx --show-bad-code -d source/ client.apk` which tells jadx to decompile as much as it can even if it leads to erroneous output.
With that I was able to see partial code.

It established a websocket connection, generated a random 64 character hexadecimal token and sent it to the server.
I could also see the message handlers to handle different type of data such as question,flag etc.
The messages from the server were plaintext json payloads with encrypted data.

I installed the app, fired up `Packet Capture` app (available in Play Store) and started sniffing the communications.
This is how the server sent a question

```
{
  "method":"question",
  "id":"733c825a-f0eb-46fa-9922-67dcf0ac2571",
  "questionText":"huMdJFzurdt+7MljZwPFtMf4FWmCGb5hWrv6Ppwpax61ga/zhrMqRkSGFgYJRhpLRU/PgDRwxYHmtWVA86lygeWCBLJ4ULGcG/mL32SfNzLvCIvwenHO1AJ/DfXLGfXJ",
  "options":["Q9vKE172ycZ+4ia+3jrPzQ==","yYHjjljeTsdS63qcvfSSKA==","P1CCdI0/PMRPlNbbAgpCRQ==","h0nL02jYw96U6sOwLwTEHg=="],
  "requestIdentifier":"75fa849d8f3cd0f98f5300d2953ee632",
  "correctAnswer":"I7J+eqlQcajZwJ3+iO6ZnylELW9NrHOUpbjYDq3rN3g="
}

```

The field `correctAnswer` contained the answer!
But the messages were encrypted. The encryption logic was given in Game.java file

```
byte[] a2 = nx.a(new nx(Game.this.getIntent().getStringExtra("id"), Game.this.getResources()).a() + ":" + jSONObject.getString("id"));
byte[] b2 = nx.b(jSONObject.getString("requestIdentifier"));
SecretKeySpec secretKeySpec = new SecretKeySpec(a2, "AES");
IvParameterSpec ivParameterSpec = new IvParameterSpec(b2);
Cipher instance = Cipher.getInstance("AES/CBC/PKCS7Padding");
instance.init(2, secretKeySpec, ivParameterSpec);
```
It used the previously generated 64 character token along with a few other parameters to create the AES key.
I really didn't wanna figure out how `nx.a` or `nx.b`  or how the client encryption worked. Their implementation was probably in the `MainActivity` method which could not decompile and the client encrypting logic was completely different as well.

So I tried another approach. 

## Smali patching!

What I needed to do was place this line of code after the cipher was initialized.

Java:

```
byte[] correctAnswer = instance.doFinal(Base64.decode(jSONObject.getString("correctAnswer"), 0));
```

Smali:
```
    const-string v7, "correctAnswer"

    invoke-virtual {v0, v7}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    const/4 v3, 0x0

    invoke-static {v7, v3}, Landroid/util/Base64;->decode(Ljava/lang/String;I)[B

    move-result-object v7

    invoke-virtual {v2, v7}, Ljavax/crypto/Cipher;->doFinal([B)[B

    move-result-object v7

    new-instance v5, Ljava/lang/String;

    invoke-direct {v5, v7}, Ljava/lang/String;-><init>([B)V
 ```

Using `apktool -d client.apk` to decompile to it to smali instead of java. 

Then editing the `Game$1.smali` file, adding the above code after line `168` after the cipher initialization takes place.
Also adding the code to log it so we can  verify it in logcat.

```
invoke-static {v5, v5}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I
```

Rebuilding the app with `apktool b client -o patched.apk` and signing it with `jarsigner`
and then `adb install patched.apk`. 

Now when I started the quiz I was able to see the index of the correct answer in adb logs 
```
adb logcat --pid=`adb shell pidof -s wtf.riceteacatpanda.quiz` '*:E'
```

Now I could have technically answered all 1000 of the question manually but here is how I automated it.

Here is the logic of the `onClickHandler` of every answer button.

```
for (final int i = 0; i < jSONObject.getJSONArray("options").length(); i++) {
                Button button = (Button) Game.this.findViewById(iArr[i]);
                button.setText(new String(instance.doFinal(Base64.decode((String) jSONObject.getJSONArray("options").get(i), 0))));
                button.setOnClickListener(new View.OnClickListener() {
                public final void onClick(View view) {
                         kr a2 = nw.a();
                         a2.a("{\"method\":\"answer\",\"answer\":" + i + "}");
                            }
                        });
               }
```

So we just need to send the string `"{"method":"answer","answer":" + correctAnswerIndex + "}"` to this method `kr a2 = nw.a(); a2.a(str);`

Here's what we need to do

1. The decrypted correct answer string needs to be trimmed for whitespaces and parsed as an Integer. So `str.trim()` and `Integer.parseInt(str)`

Smali

```
    invoke-virtual {v5}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v5

    invoke-static {v5}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v7
```

2. Remove unnecessary logic (loops,onclickhandler everything)
3. Send the answer

Smali

```

    move v3, v7 

    invoke-static {}, Lnw;->a()Lkr;

    move-result-object v5

    new-instance v6, Ljava/lang/StringBuilder;

    const-string v7, "{\"method\":\"answer\",\"answer\":"

    invoke-direct {v6, v7}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    invoke-virtual {v6, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    const-string v7, "}"

    invoke-virtual {v6, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v6}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v6

    invoke-interface {v5, v6}, Lkr;->a(Ljava/lang/String;)Z

```

Now rebuild, resign, install and start the game. It should solve itself automatically with the flag in log output.


