package ru.kokorin.astream.converter {
public class DateConverter implements AStreamConverter {
    public function fromString(string:String):Object {
        return new Date(string);
    }

    public function toString(value:Object):String {
        return String(value);
    }
}
}
