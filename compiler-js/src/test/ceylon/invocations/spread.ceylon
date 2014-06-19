import check { check }

//Tests for spread invocations
Integer spread1(Integer* a) => a.fold(0, (Integer a, Integer b) => a+b);

Integer spread2({Integer*} a) {
  variable value r  = 0;
  for (i in a) {
    r+=i;
  }
  return r;
}
Integer spread3(Integer a, Integer *b) {
  variable value r = a;
  for (i in b) {
    r+=i;
  }
  return r;
}
Integer spread4(Integer a, Integer b, Integer c) {
  return a+b+c;
}
Integer spread5(Integer a, Integer b, Integer c, Integer d=20) {
  return a+b+c-d;
}

String testIssue296(String a, String b="B") {
  return a+" "+b;
}

T issue296<T>(T(String, String=) callable, [String, String=] tup)
        => callable(*tup);

Integer(Integer*) test367_1(Integer x) => spread1;
Integer({Integer*}) test367_2(Integer x) => spread2;
Integer test367_3(Integer a)(Integer b, Integer c) {
  return b+c;
}
Integer test367_4(Integer a)(Integer b, Integer c) => b+c;

void testSpread() {
  value ints = [8,9,10];
  check(spread1(1,2,3)==6, "spread [1]");
  check(spread1(*ints)==27, "spread [2]");
  check(spread1(3,*ints)==30, "spread [3]");
  check(spread1(for (i in ints) i*10)==270, "spread [4]");
  check(spread1(2,3,for (i in ints) i*10)==275, "spread [5]");
  check(spread2{1,2,3}==6, "spread [6]");
  check(spread2{*ints}==27, "spread [7]");
  check(spread2{3,*ints}==30, "spread [8]");
  check(spread2{for (i in ints) i*10}==270, "spread [9]");
  check(spread2{2,3,for (i in ints) i*10}==275, "spread [10]");
  check(spread3(1,*ints)==28, "spread [11]");
  check(spread4(*ints)==27, "spread [12]");
  check(spread5(*ints)==7, "spread [13]");
  check(testIssue296("one") == "one B", "issue 296 [1]");
  check(issue296(testIssue296,["two", "three"])=="two three", "issue 296 [2]");
  check(issue296(testIssue296,["four"])=="four B", "issue 296 [3]");
  value params = [3,'.'];
  check("x".padLeft(*params)=="..x", "spread [14]");
  value pad = String.padLeft;
  value smrst1=pad("x")(*params);
  check(smrst1=="..x", "static method ref spread 1 expected ..x got ``smrst1``");
  value param = ['.'];
  value smrst2=pad("x")(3,*param);
  check(smrst2=="..x", "static method ref spread 2 expected ..x got ``smrst2``");
  value issue367={"hello","world"}.spread(String.padRight)(6,'!');
  check(issue367.sequence()=={"hello!","world!"}, "Issue 367 #1");
  check(ints.spread(test367_1)(1,2,3).sequence()=={6,6,6}, "Issue 367 #2");
  check(ints.spread(test367_2)({1,2,3}).sequence()=={6,6,6}, "Issue 367 #3");
  check(ints.spread(test367_3)(3,3).sequence()=={6,6,6}, "Issue 367 #4");
  check(ints.spread(test367_4)(3,3).sequence()=={6,6,6}, "Issue 367 #5");
}
