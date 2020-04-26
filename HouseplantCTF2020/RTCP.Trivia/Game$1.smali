.class final Lwtf/riceteacatpanda/quiz/Game$1;
.super Lnv;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lwtf/riceteacatpanda/quiz/Game;->onCreate(Landroid/os/Bundle;)V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic a:Landroid/media/MediaPlayer;

.field final synthetic b:Landroid/widget/TextView;

.field final synthetic c:Lwtf/riceteacatpanda/quiz/Game;


# direct methods
.method constructor <init>(Lwtf/riceteacatpanda/quiz/Game;Landroid/media/MediaPlayer;Landroid/widget/TextView;)V
    .locals 0

    iput-object p1, p0, Lwtf/riceteacatpanda/quiz/Game$1;->c:Lwtf/riceteacatpanda/quiz/Game;

    iput-object p2, p0, Lwtf/riceteacatpanda/quiz/Game$1;->a:Landroid/media/MediaPlayer;

    iput-object p3, p0, Lwtf/riceteacatpanda/quiz/Game$1;->b:Landroid/widget/TextView;

    invoke-direct {p0}, Lnv;-><init>()V

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 8

    :try_start_0
    iget-object v0, p0, Lwtf/riceteacatpanda/quiz/Game$1;->c:Lwtf/riceteacatpanda/quiz/Game;

    invoke-static {v0}, Lwtf/riceteacatpanda/quiz/Game;->a(Lwtf/riceteacatpanda/quiz/Game;)Z

    move-result v0

    if-eqz v0, :cond_0

    invoke-static {}, Lnw;->a()Lkr;

    move-result-object v0

    const-string v1, "{\"method\":\"start\"}"

    invoke-interface {v0, v1}, Lkr;->a(Ljava/lang/String;)Z

    iget-object v0, p0, Lwtf/riceteacatpanda/quiz/Game$1;->c:Lwtf/riceteacatpanda/quiz/Game;

    invoke-static {v0}, Lwtf/riceteacatpanda/quiz/Game;->b(Lwtf/riceteacatpanda/quiz/Game;)Z

    goto :goto_0

    :cond_0
    iget-object v0, p0, Lwtf/riceteacatpanda/quiz/Game$1;->a:Landroid/media/MediaPlayer;

    invoke-virtual {v0}, Landroid/media/MediaPlayer;->start()V

    :goto_0
    iget-object v0, p0, Lwtf/riceteacatpanda/quiz/Game$1;->c:Lwtf/riceteacatpanda/quiz/Game;

    new-instance v1, Lwtf/riceteacatpanda/quiz/Game$1$1;

    invoke-direct {v1, p0}, Lwtf/riceteacatpanda/quiz/Game$1$1;-><init>(Lwtf/riceteacatpanda/quiz/Game$1;)V

    invoke-virtual {v0, v1}, Lwtf/riceteacatpanda/quiz/Game;->runOnUiThread(Ljava/lang/Runnable;)V

    new-instance v0, Lorg/json/JSONObject;

    iget-object v1, p0, Lwtf/riceteacatpanda/quiz/Game$1;->d:Ljava/lang/String;

    invoke-direct {v0, v1}, Lorg/json/JSONObject;-><init>(Ljava/lang/String;)V

    new-instance v1, Lnx;

    iget-object v2, p0, Lwtf/riceteacatpanda/quiz/Game$1;->c:Lwtf/riceteacatpanda/quiz/Game;

    invoke-virtual {v2}, Lwtf/riceteacatpanda/quiz/Game;->getIntent()Landroid/content/Intent;

    move-result-object v2

    const-string v3, "id"

    invoke-virtual {v2, v3}, Landroid/content/Intent;->getStringExtra(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    iget-object v3, p0, Lwtf/riceteacatpanda/quiz/Game$1;->c:Lwtf/riceteacatpanda/quiz/Game;

    invoke-virtual {v3}, Lwtf/riceteacatpanda/quiz/Game;->getResources()Landroid/content/res/Resources;

    move-result-object v3

    invoke-direct {v1, v2, v3}, Lnx;-><init>(Ljava/lang/String;Landroid/content/res/Resources;)V

    invoke-virtual {v1}, Lnx;->a()Ljava/lang/String;

    move-result-object v1

    const-string v2, "id"

    invoke-virtual {v0, v2}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, ":"

    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Lnx;->a(Ljava/lang/String;)[B

    move-result-object v1

    const-string v2, "requestIdentifier"

    invoke-virtual {v0, v2}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    invoke-static {v2}, Lnx;->b(Ljava/lang/String;)[B

    move-result-object v2

    new-instance v3, Ljavax/crypto/spec/SecretKeySpec;

    const-string v4, "AES"

    invoke-direct {v3, v1, v4}, Ljavax/crypto/spec/SecretKeySpec;-><init>([BLjava/lang/String;)V

    new-instance v1, Ljavax/crypto/spec/IvParameterSpec;

    invoke-direct {v1, v2}, Ljavax/crypto/spec/IvParameterSpec;-><init>([B)V

    const-string v2, "AES/CBC/PKCS7Padding"

    invoke-static {v2}, Ljavax/crypto/Cipher;->getInstance(Ljava/lang/String;)Ljavax/crypto/Cipher;

    move-result-object v2

    const/4 v4, 0x2

    invoke-virtual {v2, v4, v3, v1}, Ljavax/crypto/Cipher;->init(ILjava/security/Key;Ljava/security/spec/AlgorithmParameterSpec;)V

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

    invoke-static {v5, v5}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

    invoke-virtual {v5}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v5

    invoke-static {v5}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v7

    const-string v1, "questionText"

    invoke-virtual {v0, v1}, Lorg/json/JSONObject;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    const/4 v3, 0x0

    invoke-static {v1, v3}, Landroid/util/Base64;->decode(Ljava/lang/String;I)[B

    move-result-object v1

    invoke-virtual {v2, v1}, Ljavax/crypto/Cipher;->doFinal([B)[B

    move-result-object v1

    move v4, v3

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

    :try_end_0
    .catch Lorg/json/JSONException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/security/NoSuchAlgorithmException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljavax/crypto/NoSuchPaddingException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/security/InvalidAlgorithmParameterException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljava/security/InvalidKeyException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljavax/crypto/BadPaddingException; {:try_start_0 .. :try_end_0} :catch_0
    .catch Ljavax/crypto/IllegalBlockSizeException; {:try_start_0 .. :try_end_0} :catch_0


    :cond_1
    return-void

    :catch_0
    move-exception v0

    invoke-virtual {v0}, Ljava/lang/Exception;->printStackTrace()V

    return-void

    :array_0
    .array-data 4
        0x7f07005b
        0x7f07005c
        0x7f07005d
        0x7f07005e
    .end array-data
.end method

