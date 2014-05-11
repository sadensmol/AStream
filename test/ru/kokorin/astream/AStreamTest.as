package ru.kokorin.astream {
import org.flexunit.assertThat;
import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertFalse;
import org.flexunit.asserts.assertNotNull;
import org.flexunit.asserts.assertNull;
import org.flexunit.asserts.assertTrue;
import org.hamcrest.collection.arrayWithSize;
import org.spicefactory.lib.reflect.ClassInfo;

import ru.kokorin.astream.valueobject.TestVO;

[RunWith("org.flexunit.runners.Parameterized")]
public class AStreamTest {
    private var aStream:AStream;

    [Before]
    public function setUp():void {
        aStream = new AStream();
    }

    [Test]
    public function testNull():void {
        assertEquals("aStream.toXML(null)", "<null/>", aStream.toXML(null).toXMLString());
        assertNull("aStream.fromXML(<null/>)", aStream.fromXML(XML("<null/>")));
    }

    [Test]
    public function testNaN():void {
        const infoNaN:ClassInfo = ClassInfo.forInstance(Number.NaN);
        const infoNumber:ClassInfo = ClassInfo.forClass(Number);
        const infoInt:ClassInfo = ClassInfo.forClass(int);
        const info5:ClassInfo = ClassInfo.forInstance(5);
        const info05:ClassInfo = ClassInfo.forInstance(0.5);

        assertTrue("NaN", isNaN(NaN));
        assertTrue("NaN", isNaN(Number.NaN));

        assertEquals("NaN is Number", infoNaN, infoNumber);

        assertEquals("5 is int", info5, infoInt);
        assertTrue("5 is int", 5 is int);
        assertTrue("Class(5) is not Number", info5 != infoNumber);
        assertTrue("5 is Number", 5 is Number);

        assertEquals("0.5 is Number", info05, infoNumber);
        assertTrue("0.5 is Number", 0.5 is Number);
        assertTrue("Class(0.5) is not int", info05 != infoInt);
        assertFalse("0.5 is not int", 0.5 is int);
    }


    [Test]
    public function testAttribute():void {
        aStream.useAttributeFor(TestVO, "name");
        aStream.useAttributeFor(TestVO, "value1");
        aStream.useAttributeFor(TestVO, "value2");
        aStream.useAttributeFor(TestVO, "value3");

        const original:TestVO = new TestVO("Root");
        const xml:XML = aStream.toXML(original);
        const restored:TestVO = aStream.fromXML(xml) as TestVO;

        assertNotNull("Restored object from XML", restored);
        assertEquals("xml/@value1", String(original.value1), String(xml.attribute("value1")));
        assertEquals("xml/@value2", String(original.value2), String(xml.attribute("value2")));
        assertEquals("xml/@value3", String(original.value3), String(xml.attribute("value3")));
        assertEquals("Restored and original", original.describe(), restored.describe());
    }

    public static var REFERENCE_MODES:Array = [
        [AStreamMode.ID_REFERENCES],
        [AStreamMode.SINGLE_NODE_XPATH_ABSOLUTE_REFERENCES],
        [AStreamMode.SINGLE_NODE_XPATH_RELATIVE_REFERENCES],
        [AStreamMode.XPATH_ABSOLUTE_REFERENCES],
        [AStreamMode.XPATH_RELATIVE_REFERENCES]
    ];

    [Test(dataProvider="REFERENCE_MODES")]
    public function testCircularReference(mode:AStreamMode):void {
        const original:TestVO = new TestVO("Root");
        original.children = [original];
        original.value4 = original;

        aStream.mode = mode;
        const xml:XML = aStream.toXML(original);
        const restored:TestVO = aStream.fromXML(xml) as TestVO;

        assertNotNull("Restored object from XML", restored);
        assertEquals("Restored contains self in value4", restored, restored.value4);
        assertEquals("Restored contains self in child array", restored, restored.children[0]);
    }

    [Test(dataProvider="REFERENCE_MODES")]
    public function testCollectionReference(mode:AStreamMode):void {
        const original:TestVO = new TestVO("Root");
        original.children = [new TestVO("First"), new TestVO("Second"), new TestVO("Third")];
        original.value4 = original.children;

        aStream.mode = mode;
        const xml:XML = aStream.toXML(original);
        const restored:TestVO = aStream.fromXML(xml) as TestVO;

        assertNotNull("Restored object from XML", restored);
        assertEquals("Restored.value4 equals Restored.children", restored.value4, restored.children);
        assertThat("Restored children length", restored.children, arrayWithSize(original.children.length));
    }

    [Test(expects="Error")]
    public function testCircularReferenceError():void {
        const original:TestVO = new TestVO("Root");
        original.value4 = original;

        aStream.mode = AStreamMode.NO_REFERENCES;
        const xml:XML = aStream.toXML(original);
    }

    [Test]
    public function testMultipleReferences():void {
        const original:TestVO = new TestVO("Root");
        original.children = [new TestVO("First"), new TestVO("Second"), new TestVO("Third")];
        original.value4 = original.children;

        aStream.mode = AStreamMode.NO_REFERENCES;
        const xml:XML = aStream.toXML(original);
        const restored:TestVO = aStream.fromXML(xml) as TestVO;

        assertNotNull("Restored object from XML", restored);
        assertEquals("Restored.value4 like Restored.children", String(restored.value4), String(restored.children));
        assertThat("Restored children length", restored.children, arrayWithSize(original.children.length));
    }
}
}
