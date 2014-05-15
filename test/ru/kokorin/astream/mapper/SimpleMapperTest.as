package ru.kokorin.astream.mapper {
import flash.utils.ByteArray;

import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertNotNull;
import org.spicefactory.lib.reflect.ClassInfo;

import ru.kokorin.astream.AStreamRegistry;
import ru.kokorin.astream.valueobject.EnumVO;

[RunWith("org.flexunit.runners.Parameterized")]
public class SimpleMapperTest {
    private var registry:AStreamRegistry;
    private static const STRING_CLASS:ClassInfo = ClassInfo.forClass(String);
    private static const DATE_CLASS:ClassInfo = ClassInfo.forClass(Date);
    private static const BYTEARRAY_CLASS:ClassInfo = ClassInfo.forClass(ByteArray);

    [Before]
    public function setUp():void {
        registry = new AStreamRegistry();
    }

    public static var TYPE_VALUE_PAIRS:Array = [
        [Number, 5],
        [Number, 2.5],
        [String, "The quick brown fox jumps over the lazy dog"],
        [Boolean, false],
        [Boolean, true],
        [int, -123],
        [uint, 321],
        [EnumVO, EnumVO.FIRST]
    ];
    [Test(dataProvider="TYPE_VALUE_PAIRS")]
    public function test(type:Class, value:Object):void {
        const info:ClassInfo = ClassInfo.forClass(type);
        const simpleMapper:SimpleMapper = new SimpleMapper(info, registry);
        const xml:XML = simpleMapper.toXML(value, null);
        const restored:Object = simpleMapper.fromXML(xml, null);

        assertEquals("Restored value", value, restored);
    }

    [Test]
    public function testDate():void {
        const value:Date = new Date();
        const simpleMapper:SimpleMapper = new SimpleMapper(DATE_CLASS, registry);
        const xml:XML = simpleMapper.toXML(value, null);
        const restored:Date = simpleMapper.fromXML(xml, null) as Date;

        assertEquals("Restored Date.time", value.time, restored.time);
    }

    public static var ESCAPE_PAIRS:Array = [
        ["&", "&amp;"],
        //["\"", "&quot;"], NOT escaped in AS3 XML
        //["'", "&apos;"],  NOT escaped in AS3 XML
        ["<", "&lt;"],
        [">", "&gt;"]
    ];
    [Test(dataProvider="ESCAPE_PAIRS")]
    public function testEscape(value:String, xmlText:String):void {
        const simpleMapper:SimpleMapper = new SimpleMapper(STRING_CLASS, registry);
        const xml:XML = simpleMapper.toXML(value, null);
        const restored:String = simpleMapper.fromXML(xml, null) as String;

        assertEquals("Restored String", value, restored);
        assertEquals("Escaped in XML", "<String>"+xmlText+"</String>", xml.toXMLString());
    }

    public static var TEXT_ENCODED_PAIRS:Array = [
        ["The quick brown fox jumps over the lazy dog", "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZw=="]
    ];
    [Test(dataProvider="TEXT_ENCODED_PAIRS")]
    public function testByteArray(text:String, encoded:String):void {
        const simpleMapper:SimpleMapper = new SimpleMapper(BYTEARRAY_CLASS, registry);
        const bytes:ByteArray = new ByteArray();
        bytes.writeUTFBytes(text);
        const xml:XML = simpleMapper.toXML(bytes, null);
        const restored:ByteArray = simpleMapper.fromXML(xml, null) as ByteArray;

        assertEquals("Wrong Base64 encoding", String(xml), encoded);
        assertNotNull("Failed to restore ByteArray", restored);
        assertEquals("Wrong Base64 decoding", String(restored), text);
    }

    [Test]
    public function testReset():void {
        const simpleMapper:SimpleMapper = new SimpleMapper(STRING_CLASS, registry);
        const xmlBeforeAlias:XML = simpleMapper.toXML("", null);
        registry.alias("string", STRING_CLASS);
        const xmlAfterAlias:XML = simpleMapper.toXML("", null);
        simpleMapper.reset();
        const xmlAfterReset:XML = simpleMapper.toXML("", null);

        assertEquals("Tag names before reset", xmlBeforeAlias.localName(), xmlAfterAlias.localName());
        assertEquals("Tag name after reset", "string", xmlAfterReset.localName());
    }
}
}
