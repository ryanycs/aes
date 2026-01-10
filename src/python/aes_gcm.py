"""
AES-GCM (Galois/Counter Mode) implementation
Reference: NIST SP 800-38D, https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-38d.pdf
"""

from math import ceil
from typing import Final

from aes import AES


class AESGCM:
    def __init__(self, key: bytes):
        self.ciph = AES(key)

        self.H: Final = self.ciph.encrypt(bytes(16))  # H = AES_K(0^128)
        self.t = 16  # authentication tag length in bytes

    def encrypt(self, plaintext: bytes, iv: bytes, aad: bytes):
        if len(iv) == 12:
            j0 = iv + bytes([0, 0, 0, 1])
        else:
            raise NotImplementedError("IV length other than 96 bits is not implemented.")

        C = self._gctr(self._inc32(j0), plaintext)
        u = 16 * ceil(len(C) / 16) - len(C)
        v = 16 * ceil(len(aad) / 16) - len(aad)

        # S = A || 0^u || C || 0^v || len(A)_64 || len(C)_64
        S = self._ghash(
            aad
            + bytes(v)
            + C
            + bytes(u)
            + (len(aad) * 8).to_bytes(8, "big")
            + (len(C) * 8).to_bytes(8, "big")
        )
        T = self._gctr(j0, S)[: self.t]

        return C, T

    def decrypt(self, ciphertext: bytes, iv: bytes, aad: bytes, tag: bytes):
        if len(tag) != self.t:
            raise ValueError("Indication of inauthenticity failed: invalid tag length.")

        if len(iv) == 12:
            j0 = iv + bytes([0, 0, 0, 1])
        else:
            raise NotImplementedError("IV length other than 96 bits is not implemented.")

        P = self._gctr(self._inc32(j0), ciphertext)
        u = 16 * ceil(len(ciphertext) / 16) - len(ciphertext)
        v = 16 * ceil(len(aad) / 16) - len(aad)

        # S = A || 0^u || C || 0^v || len(A)_64 || len(C)_64
        S = self._ghash(
            aad
            + bytes(v)
            + ciphertext
            + bytes(u)
            + (len(aad) * 8).to_bytes(8, "big")
            + (len(ciphertext) * 8).to_bytes(8, "big")
        )
        T = self._gctr(j0, S)[: self.t]

        if T == tag:
            return P
        else:
            raise ValueError("Indication of inauthenticity failed: tag does not match.")

    def _ghash(self, x):
        m = len(x) // 16
        y = bytes(16)  # y_0 = 0^128

        for i in range(1, m + 1):
            x_i = x[(i - 1) * 16 : i * 16]
            y = self._gf_mul(self._xor_bytes(y, x_i), self.H)

        return y

    def _gctr(self, icb, x):
        y = b""
        n = ceil(len(x) / 16)  # number of blocks
        len_x_n = len(x) % 16 if len(x) % 16 != 0 and n > 0 else 16  # length of last block
        cb = icb

        for i in range(1, n):  # i = 1 to n-1
            x_i = x[(i - 1) * 16 : i * 16]
            y_i = self._xor_bytes(x_i, self.ciph.encrypt(cb))

            y += y_i

            cb = self._inc32(cb)

        y_i = self._xor_bytes(x[(n - 1) * 16 :], self.ciph.encrypt(cb)[:len_x_n])
        y += y_i

        return y

    def _inc32(self, x: bytes) -> bytes:
        n = len(x)
        msb = x[: n - 4]
        lsb = x[n - 4 :]

        lsb = (int.from_bytes(lsb, "big") + 1) % (2**32)
        lsb = lsb.to_bytes(4, "big")

        return msb + lsb

    def _gf_mul(self, x: bytes, y: bytes) -> bytes:
        """Galois Field (2^128) multiplication of x and y"""

        R = 0xE1_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00
        z = 0
        x = int.from_bytes(x, "big")
        v = int.from_bytes(y, "big")

        for i in range(128):
            if x >> (127 - i) & 1:
                z ^= v

            if v & 1 == 0:
                v >>= 1
            else:
                v >>= 1
                v ^= R

        return z.to_bytes(16, "big")

    def _xor_bytes(self, a: bytes, b: bytes) -> bytes:
        return bytes(x ^ y for x, y in zip(a, b))
