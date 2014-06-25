"A nonempty, immutable sequence of values. The type 
 `Sequence<Element>` may be abbreviated `[Element+]`.
 
 Given a possibly-empty sequence of type `[Element*]`, the 
 `if (nonempty ...)` construct, or, alternatively, 
 `assert (nonempty ...)`, may be used to narrow to a 
 sequence type to a nonempty sequence type:
 
     [Integer*] nums = ... ;
     if (nonempty nums) {
         Integer first = nums.first;
         Integer max = max(nums);
         [Integer+] squares = nums.collect((Integer i) => i**2));
         [Integer+] sorted = nums.sort(byIncreasing((Integer i) => i));
     }
 
 Operations like `first`, `max()`, `collect()`, and `sort()`, 
 which polymorphically produce a nonempty or non-null output 
 when given a nonempty input are called 
 _emptiness-preserving_."
see (`interface Empty`)
by ("Gavin")
shared sealed interface Sequence<out Element>
        satisfies Element[] & 
                  {Element+} {
    
    "The index of the last element of the sequence."
    see (`value Sequence.size`)
    shared actual default Integer lastIndex => size-1;
    
    shared actual formal Integer size;
    
    "The first element of the sequence, that is, the element
     with index `0`."
    shared actual formal Element first;

    "The last element of the sequence, that is, the element
     with index `sequence.lastIndex`."
    shared actual formal Element last;
    
    "Returns `false`, since every `Sequence` contains at
     least one element."
    shared actual Boolean empty => false;
    
    "A nonempty sequence containing all indexes of this 
     sequence."
    shared actual default [Integer+] keys => 0..lastIndex;
    
    "This nonempty sequence."
    shared default actual [Element+] sequence() => this;
    
    "The rest of the sequence, without the first element."
    shared actual formal Element[] rest;
    
    shared default actual [Element+] reversed => reverse();
    
    shared default actual [Element+] reverse() => Reverse();
    
    "A nonempty sequence containing the elements of this
     container, sorted according to a function imposing a 
     partial order upon the elements."
    shared default actual [Element+] sort(
            "The function comparing pairs of elements."
            Comparison comparing(Element x, Element y)) {
        value array = Array(this);
        array.sortInPlace(comparing);
        return ArraySequence(array);
    }

    "A nonempty sequence containing the results of applying 
     the given mapping to the elements of this sequence."
    shared default actual [Result+] collect<Result>(
            "The transformation applied to the elements."
            Result collecting(Element element)) {
        object list
                extends Object() 
                satisfies List<Result> {
            lastIndex => outer.lastIndex;
            size = outer.size;
            shared actual Result? getFromFirst(Integer index) {
                if (0<=index<size) {
                    return collecting(outer.getElement(index));
                }
                else {
                    return null;
                }
            }
        }
        return ArraySequence(Array(list)); 
    }
    
    "Return a nonempty sequence containing the given 
     [[element]], followed by the elements of this 
     sequence."
    shared actual default [Other,Element+]
    withLeading<Other>(Other element)
            => [element, *this];
    
    "Return a nonempty sequence containing the elements of 
     this sequence, followed by the given [[elements]]."
    shared actual default [Element,Element|Other*]
    append<Other>({Other*} elements)
            => [first, *(rest chain elements)];
    
    "Return a nonempty sequence containing the elements of 
     this sequence, followed by the given [[elements]]."
    shared actual default [Element|Other+]
    prepend<Other>({Other*} elements)
            => (elements chain this).sequence();
    
    "This nonempty sequence."
    shared actual default [Element+] clone() => this;
    
    shared actual default Boolean contains(Object element) 
            => (super of List<Element>).contains(element);
    
    shared actual default Boolean shorterThan(Integer length) 
            => (super of List<Element>).shorterThan(length);
    
    shared actual default Boolean longerThan(Integer length) 
            => (super of List<Element>).longerThan(length);
    
    shared default actual Element? find
                (Boolean selecting(Element&Object elem))
            => (super of List<Element>).find(selecting);
    
    shared default actual Element? findLast
                (Boolean selecting(Element&Object elem))
            => (super of List<Element>).findLast(selecting);
    
    shared actual default Element[] repeat(Integer times)
            => (super of Element[]).repeat(times);
    
    shared actual default [Element[],Element[]] slice(Integer index)
            => [this[...index-1], this[index...]];
    
    shared actual default String string 
            => (super of Sequential<Element>).string;
    
    Element getElement(Integer index) {
        value element = getFromFirst(index);
        if (exists element) { 
            return element;
        }
        else {
            assert (is Element null);
            return null; 
        }
    }
    
    class Reverse() 
            extends Object() 
            satisfies [Element+] {
        
        size => outer.size;
        first => outer.last;
        last => outer.first;
        rest => outer[size-2:0]; //TODO!
        
        reverse() => outer;
        reversed => outer;
        
        getFromFirst(Integer index) 
                => outer.getFromFirst(size-1-index);
        
        shared actual Element[] measure(Integer from, Integer length) {
            if (length>1) {
                value start = size-1-from;
                return outer[start..start-length+1];
            }
            else {
                return [];
            }
        }
        
        span(Integer from, Integer to) => outer[to..from];
        
        shared actual Element[] spanFrom(Integer from) {
            value endIndex = size-1;
            if (from<=endIndex) { 
                return outer[endIndex-from..0];
            }
            else {
                return [];
            }
        }
        
        shared actual Element[] spanTo(Integer to) {
            value endIndex = size-1;
            if (to>=0) { 
                return outer[endIndex..endIndex-to];
            }
            else {
                return [];
            }
        }
        
        shared actual Iterator<Element> iterator() {
            value outerList=outer;
            object iterator satisfies Iterator<Element> {
                variable value index=outerList.size-1;
                next() => index<0 then finished 
                                  else outerList.getElement(index--);
                string => "``outer.string``.iterator()";
            }
            return iterator;
        }

    }
    
}

"A [[nonempty sequence|Sequence]] of the given [[elements]], 
 or  `null` if the given stream is empty. A non-null, but
 possibly empty, [[sequence|Sequential]] may be obtained 
 using the `else` operator:
 
     [Element*] sequenceOfElements = sequence(elements) else []"
by ("Gavin")
see (`function Iterable.sequence`)
shared [Element+]|Absent sequence<Element,Absent=Null>
        (Iterable<Element, Absent> elements)
        given Absent satisfies Null {
    if (nonempty sequence = elements.sequence()) {
        return sequence;
    }
    else {
        assert (is Absent null);
        return null;
    }
}

