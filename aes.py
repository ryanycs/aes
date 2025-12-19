"""
AES (Advanced Encryption Standard) implementation
Reference: FIPS PUB 197, https://nvlpubs.nist.gov/nistpubs/fips/nist.fips.197.pdf
"""

from typing import Final


class AES:
    def __init__(self, key):
        if len(key) not in [16, 24, 32]:
            raise ValueError("Key must be either 16, 24, or 32 bytes long.")

        self.key: Final = key

        self.Nk = len(key) // 4
        self.Nb = 4
        self.Nr = self.Nk + 6

        # fmt: off
        self.sbox = (
            0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5,
            0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
            0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0,
            0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
            0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc,
            0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
            0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a,
            0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
            0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0,
            0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
            0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b,
            0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
            0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85,
            0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
            0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5,
            0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
            0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17,
            0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
            0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88,
            0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
            0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
            0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
            0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9,
            0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
            0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6,
            0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
            0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e,
            0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
            0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94,
            0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
            0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68,
            0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
        )

        self.inv_sbox = (
            0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38,
            0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
            0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87,
            0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
            0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d,
            0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
            0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2,
            0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
            0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16,
            0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
            0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda,
            0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
            0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a,
            0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
            0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02,
            0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
            0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea,
            0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
            0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85,
            0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
            0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89,
            0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
            0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20,
            0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
            0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31,
            0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
            0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d,
            0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
            0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0,
            0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
            0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26,
            0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
        )
        # fmt: on

        self.rcon = self._generate_rcon()  # Round constant
        self.w = self._key_expansion()  # Round keys

    def encrypt(self, plaintext: bytes) -> bytes:
        """Encrypt a single block of 16 bytes using AES."""

        if len(plaintext) != 16:
            raise ValueError("Plaintext must be 16 bytes long.")

        state = self._input_to_state(plaintext)

        self._add_round_key(state, 0)

        for round in range(1, self.Nr):  # Round 1 to Nr-1
            self._sub_bytes(state)
            self._shift_rows(state)
            self._mix_columns(state)
            self._add_round_key(state, round)

        self._sub_bytes(state)
        self._shift_rows(state)
        self._add_round_key(state, self.Nr)

        return bytes([state[r][c] for c in range(self.Nb) for r in range(4)])

    def decrypt(self, ciphertext: bytes) -> bytes:
        """Decrypt a single block of 16 bytes using AES."""

        if len(ciphertext) != 16:
            raise ValueError("Ciphertext must be 16 bytes long.")

        state = self._input_to_state(ciphertext)

        self._add_round_key(state, self.Nr)

        for round in range(self.Nr - 1, 0, -1):  # Round (Nr - 1) to 1
            self._inv_shift_rows(state)
            self._inv_sub_bytes(state)
            self._add_round_key(state, round)
            self._inv_mix_columns(state)

        self._inv_shift_rows(state)
        self._inv_sub_bytes(state)
        self._add_round_key(state, 0)

        return bytes([state[r][c] for c in range(self.Nb) for r in range(4)])

    def print_block(self, block):
        for r in range(4):
            for c in range(len(block[0])):
                print(f"{block[r][c]:02x} ", end="")
            print()
        print()

    def print_key(self):
        for r in range(4):
            for c in range(self.Nk):
                print(f"{self.key[r + 4 * c]:02x} ", end="")
            print()

    def print_round_keys(self):
        for i in range(self.Nr + 1):
            print(f"Round Key {i}:")
            for r in range(4):
                for c in range(self.Nb):
                    print(f"{self.w[i * self.Nb + c][r]:02x} ", end="")
                print()
            print()

    def _input_to_state(self, input: bytes):
        """Convert input array to state array."""

        state = [[0] * self.Nb for _ in range(4)]
        for r in range(4):
            for c in range(self.Nb):
                state[r][c] = input[r + 4 * c]

        return state

    def _sub_bytes(self, state):
        for r in range(4):
            for c in range(self.Nb):
                state[r][c] = self.sbox[state[r][c]]

    def _inv_sub_bytes(self, state):
        for r in range(4):
            for c in range(self.Nb):
                state[r][c] = self.inv_sbox[state[r][c]]

    def _shift_rows(self, state):
        state[1] = state[1][1:] + state[1][:1]
        state[2] = state[2][2:] + state[2][:2]
        state[3] = state[3][3:] + state[3][:3]

    def _inv_shift_rows(self, state):
        state[1] = state[1][-1:] + state[1][:-1]
        state[2] = state[2][-2:] + state[2][:-2]
        state[3] = state[3][-3:] + state[3][:-3]

    def _mix_columns(self, state):
        for c in range(self.Nb):
            s0 = state[0][c]
            s1 = state[1][c]
            s2 = state[2][c]
            s3 = state[3][c]

            state[0][c] = self._gm2(s0) ^ self._gm3(s1) ^ s2 ^ s3
            state[1][c] = s0 ^ self._gm2(s1) ^ self._gm3(s2) ^ s3
            state[2][c] = s0 ^ s1 ^ self._gm2(s2) ^ self._gm3(s3)
            state[3][c] = self._gm3(s0) ^ s1 ^ s2 ^ self._gm2(s3)

    def _inv_mix_columns(self, state):
        for c in range(self.Nb):
            s0 = state[0][c]
            s1 = state[1][c]
            s2 = state[2][c]
            s3 = state[3][c]

            state[0][c] = self._gm14(s0) ^ self._gm11(s1) ^ self._gm13(s2) ^ self._gm9(s3)
            state[1][c] = self._gm9(s0) ^ self._gm14(s1) ^ self._gm11(s2) ^ self._gm13(s3)
            state[2][c] = self._gm13(s0) ^ self._gm9(s1) ^ self._gm14(s2) ^ self._gm11(s3)
            state[3][c] = self._gm11(s0) ^ self._gm13(s1) ^ self._gm9(s2) ^ self._gm14(s3)

    def _add_round_key(self, state, round):
        for col in range(self.Nb):
            for row in range(4):
                state[row][col] ^= self.w[round * self.Nb + col][row]

    def _generate_rcon(self):
        """Generate the round constant (Rcon) array."""
        rcon = []

        x = 0x8D
        rcon.append([x, 0x00, 0x00, 0x00])
        for _ in range(self.Nr):
            x = self._xtime(x)
            rcon.append([x, 0x00, 0x00, 0x00])

        return rcon

    def _sub_word(self, word):
        return [self.sbox[b] for b in word]

    def _rot_word(self, word):
        return [word[1], word[2], word[3], word[0]]

    def _xor_word(self, word1, word2):
        return [b1 ^ b2 for b1, b2 in zip(word1, word2)]

    def _key_expansion(self):
        w = [[0] * 4 for _ in range(self.Nb * (self.Nr + 1))]

        i = 0
        while i < self.Nk:
            w[i] = [
                self.key[4 * i],
                self.key[4 * i + 1],
                self.key[4 * i + 2],
                self.key[4 * i + 3],
            ]
            i = i + 1

        i = self.Nk
        while i < self.Nb * (self.Nr + 1):
            temp = w[i - 1]
            if i % self.Nk == 0:
                temp = self._xor_word(self._sub_word(self._rot_word(temp)), self.rcon[i // self.Nk])
            elif self.Nk > 6 and i % self.Nk == 4:
                temp = self._sub_word(temp)

            w[i] = self._xor_word(w[i - self.Nk], temp)
            i = i + 1

        return w

    def _xtime(self, n):
        return ((n << 1) ^ (0x1B if (n & 0x80) else 0x00)) & 0xFF

    def _gm2(self, n):
        return self._xtime(n)

    def _gm3(self, n):
        return self._xtime(n) ^ n

    def _gm4(self, n):
        return self._gm2(self._gm2(n))

    def _gm8(self, n):
        return self._gm2(self._gm4(n))

    def _gm9(self, n):
        return self._gm8(n) ^ n

    def _gm11(self, n):
        return self._gm8(n) ^ self._gm2(n) ^ n

    def _gm13(self, n):
        return self._gm8(n) ^ self._gm4(n) ^ n

    def _gm14(self, n):
        return self._gm8(n) ^ self._gm4(n) ^ self._gm2(n)
