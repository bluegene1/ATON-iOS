//
//  platonWalletTests.swift
//  platonWalletTests
//
//  Created by juzix on 2018/10/20.
//  Copyright © 2018 ju. All rights reserved.
//

import XCTest
import BigInt
@testable import platonWallet

extension UInt16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension UInt32 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
    }
}

extension UInt64 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt64>.size)
    }
}



class platonWalletTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testUtil(){
        
        let tmp = BigUInt("0000010")
        let sss = String(tmp!)
        
        XCTAssertTrue("0.11".isValidInputAmoutWith8DecimalPlace())
        XCTAssertFalse("0000.1".isValidInputAmoutWith8DecimalPlace())
        XCTAssertFalse("0.123456789".isValidInputAmoutWith8DecimalPlace())
        
    
        XCTAssertEqual("0.", "0.0".trimDecimalTailingZero())
        XCTAssertEqual("00.", "00.00".trimDecimalTailingZero())
        XCTAssertEqual("10.", "10.000".trimDecimalTailingZero())
        XCTAssertEqual("10.1", "10.100".trimDecimalTailingZero())
        
        XCTAssertEqual("123457000", String((BigUInt("123456789")?.ceilToDecimal(round: 3))!))
        XCTAssertEqual("123456000", String((BigUInt("123456789")?.floorToDecimal(round: 3))!))
        
        
        XCTAssertEqual("111111111111000000010000000000", String((BigUInt("111111111111000000000012345678")?.ceilToDecimal(round: 10))!))
        XCTAssertEqual("11120000000000", String((BigUInt("11110123456789")?.ceilToDecimal(round: 10))!))
        
        XCTAssertEqual("111111111111000000000000000000", String((BigUInt("111111111111000000000012345678")?.floorToDecimal(round: 10))!))
        XCTAssertEqual("11110000000000", String((BigUInt("11110123456789")?.floorToDecimal(round: 10))!))

        
    }
    
    func testRlpDecode(){
        
        let rlpItem = try? RLPDecoder().decode([0xc1,0x80])
        var transactionId = Data(bytes: rlpItem!.array![0].bytes!).safeGetUnsignedLong(at: 0, bigEndian: true)
        print("d")
        
    }
    
    func testSendAmoutInput(){
        
        assert(!".0...1".isValidInputAmoutWith8DecimalPlace())
        assert(!"..1".isValidInputAmoutWith8DecimalPlace())
        assert(!"9.111.".isValidInputAmoutWith8DecimalPlace())
        assert(!"9.123456789".isValidInputAmoutWith8DecimalPlace())
        assert(!".111".isValidInputAmoutWith8DecimalPlace())
        assert("0.111".isValidInputAmoutWith8DecimalPlace())
    
    }
    
    func testUIntUtilTest(){
        let intdata16 : UInt16 = 1
        let data16 = intdata16.data
        let data16Hex = data16.hexString
        print("")
        
        let intdata32 : UInt32 = 1
        let data32 = intdata32.littleEndian.data
        let data32Hex = data32.hexString
        print("")
        
        let intdata64 : UInt64 = 1
        let data64 = intdata64.data
        let thebytes = data64.bytes
        let data64Hex = data64.hexString
        print("")
        
    }

    func testBigUintExtensionTest() {
        
        let ret1 = BigUInt("1234567893333")?.divide(by: "10000000000", round: 8)
        XCTAssertEqual(ret1, "123.45678933")
        
        let ret2 = BigUInt("1234567893333")?.divide(by: "10000000000", round: 1)
        XCTAssertEqual(ret2, "123.4")
        
        let ret3 = BigUInt("1234567893333000000000000000000000000000000")?.divide(by: "10000000000", round: 1)
        XCTAssertEqual(ret3, "123456789333300000000000000000000")
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let divideret1 = BigUInt("21000")?.divide(by: "10000", round: 4)
        XCTAssertEqual(divideret1, "2.1")
        
        let divideret2 = BigUInt("21000")?.divide(by: "100000", round: 4)
        XCTAssertEqual(divideret2, "0.21")
        
        let divideret3 = BigUInt("21000000000000")?.divide(by: "1000000000000000000", round: 100)
        XCTAssertEqual(divideret3, "0.000021")
    }
    
    func testPlatonContranctDeploy(){
        
        let web3 = Web3(rpcURL: "http://192.168.7.184:8545")
        
        let abi = "{\"version\":\"0.01\",\"abi\":[{\"method\":\"transfer\",\"args\":[{\"name\":\"from\",\"typeName\":\"\",\"realTypeName\":\"string\"},{\"name\":\"to\",\"typeName\":\"\",\"realTypeName\":\"string\"},{\"name\":\"balance\",\"typeName\":\"\",\"realTypeName\":\"int32\"}],\"return\":\"void\",\"funcType\":\"\"},{\"method\":\"transfer02\",\"args\":[{\"name\":\"from\",\"typeName\":\"\",\"realTypeName\":\"string\"},{\"name\":\"to\",\"typeName\":\"\",\"realTypeName\":\"string\"},{\"name\":\"balance\",\"typeName\":\"\",\"realTypeName\":\"int32\"}],\"return\":\"void\",\"funcType\":\"\"},{\"method\":\"getBalance\",\"args\":[{\"name\":\"from\",\"typeName\":\"\",\"realTypeName\":\"string\"}],\"return\":\"string\",\"funcType\":\"const\"}],\"event\":[{\"name\":\"Notify\",\"args\":[{\"typeName\":\"string\"}]},{\"name\":\"NotifyWithCode\",\"args\":[{\"typeName\":\"int32\"},{\"typeName\":\"string\"}]}]}"
        let path = Bundle.main.path(forResource: "PlatonAssets/demo01", ofType: "wasm")
        let bin = try? Data(contentsOf: URL(fileURLWithPath: path!))
        
        let txTypePart = RLPItem(bytes: [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01])
        let binPart = RLPItem(bytes: (bin?.bytes)!)
        let abiPart = RLPItem(bytes: (abi.data(using: .utf8)?.bytes)!)

        let rlp = RLPItem(arrayLiteral: txTypePart,binPart,abiPart)
        
        let rawRlp = try? RLPEncoder().encode(rlp)
        let rlpHex = rawRlp?.toHexString()
        
        let tmpAddr = EthereumAddress(hexString: "0xAa9afdCf179EBd392767F4113eF02B018D937488")
        let tmpQuan = EthereumQuantity(quantity: BigUInt("0")!)
        let call = EthereumCall(from: tmpAddr, to: tmpAddr!, gas: tmpQuan, gasPrice: tmpQuan, value: tmpQuan, data: EthereumData(bytes: rawRlp!))
        
        web3.eth.estimateGas(call: call) { (resp) in
            print("\(resp)")
            print("\(String((resp.result?.quantity)!))")
            print("\(self)")
        }
        
        
        print("bin length")
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    
    

}
