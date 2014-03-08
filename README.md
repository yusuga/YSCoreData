YSCoreData
===
CoreDataをマルチスレッドで使用するためのヘルパーです。

概要
---

[Multi-Context CoreData | Cocoanetics](http://www.cocoanetics.com/2012/07/multi-context-coredata/)を参考に実装しました。
![http://www.cocoanetics.com/2012/07/multi-context-coredata/](http://cl.ly/image/322H2D2F3I3K/Bildschirmfoto-2012-07-18-um-4.14.55-PM.png)

<[Cocoanetics](http://www.cocoanetics.com/2012/07/multi-context-coredata/)>

このような実装です。

※ 間違い等ご指摘いただけると幸いです。

使用方法
---
Overrideでの使用を想定しています。詳しくはExampleをご参考下さい。ExampleではTwitterを想定して実装しています。

CocoaPods
---

    pod 'YSCoreData', :git => 'https://github.com/yusuga/YSCoreData.git'

or  

    pod repo add yusuga git:github.com/yusuga/podspec.git
    pod 'YSCoreData'

License
---
    Copyright &copy; 2014 Yu Sugawara (https://github.com/yusuga)
    Licensed under the MIT License.

    Permission is hereby granted, free of charge, to any person obtaining a 
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.