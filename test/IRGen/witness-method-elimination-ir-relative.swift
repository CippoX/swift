// Tests that under -enable-llvm-wme, IRGen marks wtables and wcall sites with
// the right attributes and intrinsics.

// RUN: %target-build-swift -Xfrontend -disable-objc-interop -Xfrontend -enable-llvm-wme \
// RUN:    -Xfrontend -enable-relative-protocol-witness-tables \
// RUN:    %s -emit-ir -o - | %FileCheck %s --check-prefix=CHECK --check-prefix=CHECK-%target-ptrsize

// REQUIRES: PTRSIZE=64

protocol TheProtocol {
  func func1_live()
  func func2_dead()
}

struct MyStruct : TheProtocol {
  func func1_live() { print("MyStruct.func1_live") }
  func func2_dead() { print("MyStruct.func2_dead") }
}


// CHECK: @"$s4main8MyStructVAA11TheProtocolAAWP" =
// CHECK-SAME: hidden constant [3 x i32]
// CHECK-SAME:  i32 trunc {{.*}} @"$s4main8MyStructVAA11TheProtocolAAMc"
// CHECK-SAME:  i32 trunc {{.*}} @"$s4main8MyStructVAA11TheProtocolA2aDP10func1_liveyyFTW"
// CHECK-SAME:  i32 trunc {{.*}} @"$s4main8MyStructVAA11TheProtocolA2aDP10func2_deadyyFTW"
// CHECK-SAME: ], align 8, !type !0, !type !1, !vcall_visibility !2, !typed_global_not_for_cfi !3

func test1() {
  // CHECK: define hidden swiftcc void @"$s4main5test1yyF"()
  let x: MyStruct = MyStruct()
  x.func1_live()
  // CHECK:      call swiftcc void @"$s4main8MyStructVACycfC"()
  // CHECK-NEXT: call swiftcc void @"$s4main8MyStructV10func1_liveyyF"()
  // CHECK-NEXT: ret void
}

func test2() {
  // CHECK: define hidden swiftcc void @"$s4main5test2yyF"()
  let x: TheProtocol = MyStruct()
  x.func1_live()
  // CHECK: [[TBL:%.*]] = phi i8**
  // CHECK: [[TBL2:%.*]] = bitcast i8** [[TBL]] to i32*
  // CHECK: [[ENTRY:%.*]] = getelementptr inbounds i32, i32* [[TBL2]], i32 1
  // CHECK: [[ENTRY2:%.*]] = bitcast i32* [[ENTRY]] to i8*
  // CHECK: call { i8*, i1 } @llvm.type.checked.load.relative(i8* [[ENTRY2]], i32 0, metadata !"$s4main11TheProtocolP10func1_liveyyFTq")
}

// CHECK: !0 = !{i64 4, !"$s4main11TheProtocolP10func1_liveyyFTq"}
// CHECK: !1 = !{i64 8, !"$s4main11TheProtocolP10func2_deadyyFTq"}
// CHECK: !2 = !{i64 1, i64 4, i64 12}
// CHECK: !3 = !{}
