import gmpy2
import random
from Crypto.Util.number import *

###################################################################################
################################ Utility Libraries ################################
###################################################################################

def getPrimes(size):
    half = random.randint(16, size // 2 - 8)
    rand = random.randint(8, half - 1)
    sizes = [rand, half, size - half - rand]
    print(sizes)
    while True:
        p, q = 0, 0
        for s in sizes:
            p <<= s
            q <<= s
            chunk = random.getrandbits(s)
            # print("==> ", p, q)
            p += chunk
            if s == sizes[1]:
                chunk = random.getrandbits(s)
            q += chunk
            # print(">>>>>", p, q)
        # print(hex(p), hex(q))
        p |= 2**(size - 1) | 2**(size - 2) | 1
        q |= 2**(size - 1) | 2**(size - 2) | 1
        # print(hex(p), hex(q))
        if gmpy2.is_prime(p) and gmpy2.is_prime(q):
            return p, q

gmpy2.get_context().precision=4096

def bitFactor(n):
    # First find the most significant bits that are a sqaure
    nhex = hex(n)[2:]
    while not is_square(eval('0x'+nhex)):
        # print(nhex)
        nhex = nhex[1:]
    return nhex

def legendre_symbol(a, p):
    """
    Legendre symbol
    Define if a is a quadratic residue modulo odd prime
    http://en.wikipedia.org/wiki/Legendre_symbol
    """
    ls = pow(a, (p - 1)//2, p)
    if ls == p - 1:
        return -1
    return ls


def _prime_mod_sqrt(a, p):
    """
    Square root modulo prime number
    Solve the equation:
        x^2 = a mod p
    and return x. Note that p - x is also a solution.
    Variable a must be a quadratic residue modulo p
    Variable p must be an odd prime
    http://en.wikipedia.org/wiki/Tonelli-Shanks_algorithm
    """
    # Reduce a mod p
    a %= p
    # Special case which solution is simple
    if p % 4 == 3:
        x = pow(a, (p + 1)//4, p)
        return x
    # Factor p-1 on the form q * 2^s (with Q odd)
    q, s = p - 1, 0
    while q % 2 == 0:
        q, s = q >> 1, s + 1
    # Select a z which is a quadratic non resudue modulo p
    z = 1
    while legendre_symbol(z, p) != -1:
        z += 1
    c = pow(z, q, p)
    # Search for a solution
    x = pow(a, (q + 1)//2, p)
    t = pow(a, q, p)
    m = s
    while t != 1:
        # Find the lowest i such that t^(2^i) = 1
        e = 2
        for i in range(1, m):
            if pow(t, e, p) == 1:
                break
            e *= 2
        # Update next value to iterate
        b = pow(c, 1 << (m - i - 1), p)
        x = (x * b) % p
        t = (t * b * b) % p
        c = (b * b) % p
        m = i
    return x
def invmod(a,b): return 0 if a==0 else 1 if b%a==0 else b - invmod(b%a,a)*b//a

def prime_mod_sqrt(a, p, e=1):
    """
    Square root modulo prime power number
    Solve the equation:
        x^2 = a mod p^e
    and return list of x solution
    http://en.wikipedia.org/wiki/Hensel's_lemma
    http://www.johndcook.com/quadratic_congruences.html
    """
    # Reduce a mod p^e
    a %= p**e
    # Handle prime 2 special case
    if p == 2:
        if e >= 3 and a % 8 == 1:
            res = []
            for x in [1, 3]:
                for k in range(3, e):
                    i = (x*x - a)/(2**k) % 2
                    x = x + i*2**(k-1)
                res.append(x)
                res.append(p**e - x)
            return res
        # No solution if a is odd and a % 8 != 1
        if e >= 3 and a % 2 == 1:
            return []
        # Force brut if a is even or e < 3 (for now)
        return [x for x in range(0, p**e) if x*x % p**e == a % p**e]
    # Check solution existence on odd prime
    ls = legendre_symbol(a, p)
    if ls == -1:
        return []
    # Case were a is 0 or p multiple
    if ls == 0:
        if a % p**e == 0:
            return [0]
        return []
    # Hensel lemma lifting from x^2 = a mod p solution
    x  = _prime_mod_sqrt(a, p)
    for i in range(1, e):
        f = x*x - a
        fd = 2*x
        t = - (f / p**i) *invmod(fd, p**i)
        x = x + t * p**i % p**(i+1)
    return [x, p**e - x]

###################################################################################
#################################### Real shit! ###################################
###################################################################################

def getRoot(N):
    possiblePartials = [int(i) for i in prime_mod_sqrt(gmpy2.mpz(N%2**2048), 2, 1024)]
    nhex = hex(N)
    correctAns = 0
    # Now choose the best candidate root 
    for i in possiblePartials:
        if hex(i**2)[:4] == nhex[:4]:
            return i
    print("Root not found!")
    return 0

def getPartialRoot(N, root, nr_bytes = 32):
    """
    This is a hack but apparently it works! Sometimes (rarely, but in this scenario as well) we
    encounter N which have no modulo square root such that root^2 > N
    This works I think because We are preserving some portion of MSB along with a major portion of LSB,
    and so the number that is generated has a statistical property of that of a real root. In other words, 
    its a guess work that works everytime ;_;
    """
    Nroot = int(gmpy2.sqrt(N)).to_bytes(128, 'big')
    root = root.to_bytes(128, 'big')
    newRoot = eval('0x' + Nroot[:nr_bytes].hex() + root[nr_bytes:].hex())
    return newRoot

def cracker(N, root):
    """ 
    We know that N = p*q --> N = (a+b)*(a-b) <=> N = a^2 - b^2 from fermat's factorization method
    Thus, b^2 = a^2 - N. Now, We discovered that Primes generated by the getPrimes method above
    Always generates primes that are symmetric around one of the modular square root of N modulo 2^1024.
    The choosen root shall always satisfy the condition root^2 > N. 
    Thus, we can have a = root, and b as the deviation from a to give p and q
    Thus, b = sqrt(a^2 - N) given (a^2 - N) is a perfect square
    """
    bsquare = root**2 - N
    if bsquare < 0:
        return 0, 0
    b = gmpy2.sqrt(root**2 - N)
    if int(b)**2 != int(bsquare):
        return 0, 0
    p = int(root + b) 
    q = int(root - b)
    return p, q

def solver(N, nr_bytes=32):
    ans = getRoot(N)
    if ans == 0:
        # No proper roots were found, lets use a random root
        possiblePartials = [int(i) for i in prime_mod_sqrt(gmpy2.mpz(N%2**2048), 2, 1024)]
        for root in possiblePartials:
            root = getPartialRoot(N, root, nr_bytes)
            print("Using Partial Root: ", root)
            p, q = cracker(N, root)
            if p * q == N:
                print("Root FOund!!!!", hex(p), hex(q))
                return p, q
    else:
        p, q = cracker(N, ans)
        if p * q == N:
            print("Root FOund!!!!", hex(p), hex(q))
            return p, q

N = 0xf7e6ddd1f49d9f875904d1280c675e0e03f4a02e2bec6ca62a2819d521441b727d313ec1b5f855e3f2a69516a3fea4e953435cbf7ac64062dd97157b6342912b7667b190fad36d54e378fede2a7a6d4cc801f1bc93159e405dd6d496bf6a11f04fdc04b842a84238cc3f677af67fa307b2b064a06d60f5a3d440c4cfffa4189e843602ba6f440a70668e071a9f18badffb11ed5cdfa6b49413cf4fa88b114f018eb0bba118f19dea2c08f4393b153bcbaf03ec86e2bab8f06e3c45acb6cd8d497062f5fdf19f73084a3a793fa20757178a546de902541dde7ff6f81de61a9e692145a793896a8726da7955dab9fc0668d3cfc55cd7a2d1d8b631f88cf5259ba1
c = 0xf177639388156bd71b533d3934016cc76342efae0739cb317eb9235cdb97ae50b1aa097f16686d0e171dccc4ec2c3747f9fbaba4794ee057964734835400194fc2ffa68a5c6250d49abb68a9e540b3d8dc515682f1cd61f46352efc8cc4a1fe1d975c66b1d53f6b5ff25fbac9fa09ef7a3d7e93e2a53f9c1bc1db30eed92a30586388cfef4d68516a8fdebe5ebf9c7b483718437fcf8693acd3118544249b6e62d30afa7def37aecf4da999c1e2b686ca9caca1b84503b8794273381b51d06d0dfb9c19125ce30e67a8cf72321ca8c50a481e4b96bbbc5b8932e8d5a32fa040c3e29ced4c8bf3541e846f832a7f9406d263a592c0a9bce88be6aed043a9867a7

p, q = solver(N)
phi = (p-1)*(q-1)
e = 65537
d = gmpy2.invert(e, phi)
m = pow(c, d, N)
print("Decrypting the message...")
print(long_to_bytes(m))