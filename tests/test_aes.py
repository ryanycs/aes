from aes import AES


def test_aes():
    # Case 1
    plaintext = bytes.fromhex("00112233445566778899aabbccddeeff")
    key = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
    expected_ciphertext = bytes.fromhex("69c4e0d86a7b0430d8cdb78070b4c55a")

    aes = AES(key)

    ciphertext = aes.encrypt(plaintext)
    assert ciphertext == expected_ciphertext

    decripted = aes.decrypt(ciphertext)
    assert decripted == plaintext

    # Case 2
    plaintext = bytes.fromhex("3243f6a8885a308d313198a2e0370734")
    key = bytes.fromhex("2b7e151628aed2a6abf7158809cf4f3c")
    expected_ciphertext = bytes.fromhex("3925841d02dc09fbdc118597196a0b32")

    aes = AES(key)

    ciphertext = aes.encrypt(plaintext)
    print(ciphertext.hex())
    assert ciphertext == expected_ciphertext

    decripted = aes.decrypt(ciphertext)
    assert decripted == plaintext
