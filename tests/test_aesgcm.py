from aes_gcm import AESGCM


def test_aes_gcm():
    """Test AES-GCM encryption with test vectors from The Galois/Counter Mode of Operation (GCM) AES Test Vectors"""

    # Test Case 1
    key = bytes.fromhex("00000000000000000000000000000000")
    aesgcm = AESGCM(key)
    iv = bytes.fromhex("000000000000000000000000")
    c, t = aesgcm.encrypt(bytes(), iv, bytes())
    assert aesgcm.H == bytes.fromhex("66e94bd4ef8a2c3b884cfa59ca342b2e")
    assert c == bytes.fromhex("")
    assert t == bytes.fromhex("58e2fccefa7e3061367f1d57a4e7455a")

    # Test Case 2
    key = bytes.fromhex("00000000000000000000000000000000")
    aesgcm = AESGCM(key)
    plantext = bytes.fromhex("00000000000000000000000000000000")
    iv = bytes.fromhex("000000000000000000000000")
    c, t = aesgcm.encrypt(plantext, iv, bytes())
    assert aesgcm.H == bytes.fromhex("66e94bd4ef8a2c3b884cfa59ca342b2e")
    assert c == bytes.fromhex("0388dace60b6a392f328c2b971b2fe78")
    assert t == bytes.fromhex("ab6e47d42cec13bdf53a67b21257bddf")
    p = aesgcm.decrypt(c, iv, bytes(), t)
    assert p == plantext

    # Test Case 3
    key = bytes.fromhex("feffe9928665731c6d6a8f9467308308")
    aesgcm = AESGCM(key)
    plaintext = bytes.fromhex(
        "d9313225f88406e5a55909c5aff5269a"
        "86a7a9531534f7da2e4c303d8a318a72"
        "1c3c0c95956809532fcf0e2449a6b525"
        "b16aedf5aa0de657ba637b391aafd255"
    )
    iv = bytes.fromhex("cafebabefacedbaddecaf888")
    c, t = aesgcm.encrypt(plaintext, iv, bytes())
    assert aesgcm.H == bytes.fromhex("b83b533708bf535d0aa6e52980d53b78")
    assert c == bytes.fromhex(
        "42831ec2217774244b7221b784d0d49c"
        "e3aa212f2c02a4e035c17e2329aca12e"
        "21d514b25466931c7d8f6a5aac84aa05"
        "1ba30b396a0aac973d58e091473f5985"
    )
    assert t == bytes.fromhex("4d5c2af327cd64a62cf35abd2ba6fab4")
    p = aesgcm.decrypt(c, iv, bytes(), t)
    assert p == plaintext

    # Test Case 4
    key = bytes.fromhex("feffe9928665731c6d6a8f9467308308")
    aesgcm = AESGCM(key)
    plaintext = bytes.fromhex(
        "d9313225f88406e5a55909c5aff5269a"
        "86a7a9531534f7da2e4c303d8a318a72"
        "1c3c0c95956809532fcf0e2449a6b525"
        "b16aedf5aa0de657ba637b39"
    )
    aad = bytes.fromhex("feedfacedeadbeeffeedfacedeadbeefabaddad2")
    iv = bytes.fromhex("cafebabefacedbaddecaf888")
    c, t = aesgcm.encrypt(plaintext, iv, aad)
    assert aesgcm.H == bytes.fromhex("b83b533708bf535d0aa6e52980d53b78")
    assert c == bytes.fromhex(
        "42831ec2217774244b7221b784d0d49c"
        "e3aa212f2c02a4e035c17e2329aca12e"
        "21d514b25466931c7d8f6a5aac84aa05"
        "1ba30b396a0aac973d58e091"
    )
    assert t == bytes.fromhex("5bc94fbc3221a5db94fae95ae7121a47")
    p = aesgcm.decrypt(c, iv, aad, t)
    assert p == plaintext


def test_aes_gctr():
    """Test AES-GCTR function with test vectors from NIST SP 800-38A Appendix F.5.1"""

    key = bytes.fromhex("2b7e151628aed2a6abf7158809cf4f3c")
    aesgcm = AESGCM(key)

    # Block 1
    icb = bytes.fromhex("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
    plaintext = bytes.fromhex("6bc1bee22e409f96e93d7e117393172a")
    expected_ciphertext = bytes.fromhex("874d6191b620e3261bef6864990db6ce")
    ciphertext = aesgcm._gctr(icb, plaintext)
    assert ciphertext == expected_ciphertext

    # Block 2
    icb = bytes.fromhex("f0f1f2f3f4f5f6f7f8f9fafbfcfdff00")
    plaintext = bytes.fromhex("ae2d8a571e03ac9c9eb76fac45af8e51")
    expected_ciphertext = bytes.fromhex("9806f66b7970fdff8617187bb9fffdff")
    ciphertext = aesgcm._gctr(icb, plaintext)
    assert ciphertext == expected_ciphertext

    # Block 3
    icb = bytes.fromhex("f0f1f2f3f4f5f6f7f8f9fafbfcfdff01")
    plaintext = bytes.fromhex("30c81c46a35ce411e5fbc1191a0a52ef")
    expected_ciphertext = bytes.fromhex("5ae4df3edbd5d35e5b4f09020db03eab")
    ciphertext = aesgcm._gctr(icb, plaintext)
    assert ciphertext == expected_ciphertext

    # Block 4
    icb = bytes.fromhex("f0f1f2f3f4f5f6f7f8f9fafbfcfdff02")
    plaintext = bytes.fromhex("f69f2445df4f9b17ad2b417be66c3710")
    expected_ciphertext = bytes.fromhex("1e031dda2fbe03d1792170a0f3009cee")
    ciphertext = aesgcm._gctr(icb, plaintext)
    assert ciphertext == expected_ciphertext

    # Block 1 ~ Block 4
    icb = bytes.fromhex("f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff")
    plaintext = bytes.fromhex(
        "6bc1bee22e409f96e93d7e117393172a"
        "ae2d8a571e03ac9c9eb76fac45af8e51"
        "30c81c46a35ce411e5fbc1191a0a52ef"
        "f69f2445df4f9b17ad2b417be66c3710"
    )
    expected_ciphertext = bytes.fromhex(
        "874d6191b620e3261bef6864990db6ce"
        "9806f66b7970fdff8617187bb9fffdff"
        "5ae4df3edbd5d35e5b4f09020db03eab"
        "1e031dda2fbe03d1792170a0f3009cee"
    )
    ciphertext = aesgcm._gctr(icb, plaintext)
    assert ciphertext == expected_ciphertext
