//
//  RSSExampleData.swift
//  IceCubesApp
//
//  Created by Duong Thai on 28/02/2024.
//


#if DEBUG
import Foundation
import RSParser

enum RSSExampleData {
  static let htmlString = """
<p>Swift 5.8 is now officially released! 🎉 This release includes major additions to the <a href="#language-and-standard-library">language and standard library</a>, including <code class="language-plaintext highlighter-rouge">hasFeature</code> to support piecemeal adoption of upcoming features, an improved <a href="#developer-experience">developer experience</a>, improvements to tools in the Swift ecosystem including <a href="#swift-docc">Swift-DocC</a>, <a href="#swift-package-manager">Swift Package Manager</a>, and <a href="#swiftsyntax">SwiftSyntax</a>, refined <a href="#windows-platform">Windows support</a>, and more.</p>

<p>Thank you to everyone in the Swift community who made this release possible. Your Swift Forums discussions, bug reports, pull requests, educational content, and other contributions are always appreciated!</p>

<p>For a quick dive into some of what’s new in Swift 5.8, check out this <a href="https://github.com/twostraws/whats-new-in-swift-5-8">playground</a> put together by Paul Hudson.</p>

<p><a href="https://docs.swift.org/swift-book/documentation/the-swift-programming-language/">The Swift Programming Language</a> book has been updated for Swift 5.8 and is now published with DocC. This is the official Swift guide and a great entry point for those new to Swift. The Swift community also maintains a number of <a href="/documentation/tspl/#translations">translations</a>.</p>

<h2 id="language-and-standard-library">Language and Standard Library</h2>

<p>Swift 5.8 enables you to start incrementally preparing your projects for Swift 6 by <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0362-piecemeal-future-features.md">using <em>upcoming features</em></a>. By default, upcoming features are disabled. To enable a feature, pass the compiler flag <code class="language-plaintext highlighter-rouge">-enable-upcoming-feature</code> followed by the feature’s identifier.</p>

<p>Feature identifiers can also be <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0362-piecemeal-future-features.md#feature-detection-in-source-code">used in source code</a> using <code class="language-plaintext highlighter-rouge">#if hasFeature(FeatureIdentifier)</code> so that code can still compile with older tools where the upcoming feature is not available.</p>

<p>Swift 5.8 includes upcoming features for the following Swift evolution proposals:</p>

<ul>
  <li>SE-0274: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0274-magic-file.md">Concise magic file names</a> (<code class="language-plaintext highlighter-rouge">ConciseMagicFile</code>)</li>
  <li>SE-0286: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0286-forward-scan-trailing-closures.md">Forward-scan matching for trailing closures</a> (<code class="language-plaintext highlighter-rouge">ForwardTrailingClosures</code>)</li>
  <li>SE-0335: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md">Introduce existential any</a> (<code class="language-plaintext highlighter-rouge">ExistentialAny</code>)</li>
  <li>SE-0354: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0354-regex-literals.md">Regex literals</a> (<code class="language-plaintext highlighter-rouge">BareSlashRegexLiterals</code>)</li>
</ul>

<p>For example, building the following file at <code class="language-plaintext highlighter-rouge">/Users/example/Desktop/0274-magic-file.swift</code> in a module called <code class="language-plaintext highlighter-rouge">MagicFile</code> with <code class="language-plaintext highlighter-rouge">-enable-experimental-feature ConciseMagicFile</code> will opt into the concise format for <code class="language-plaintext highlighter-rouge">#file</code> and <code class="language-plaintext highlighter-rouge">#filePath</code> described in SE-0274:</p>

<div class="language-swift highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="nf">print</span><span class="p">(</span><span class="k">#file</span><span class="p">)</span>
<span class="nf">print</span><span class="p">(</span><span class="k">#filePath</span><span class="p">)</span>
<span class="nf">fatalError</span><span class="p">(</span><span class="s">"Something bad happened!"</span><span class="p">)</span>
</code></pre></div></div>

<p>The above code will produce the following output:</p>

<div class="language-plaintext highlighter-rouge"><div class="highlight"><pre class="highlight"><code>MagicFile/0274-magic-file.swift
/Users/example/Desktop/0274-magic-file.swift
Fatal error: Something bad happened!: file MagicFile/0274-magic-file.swift, line 3
</code></pre></div></div>

<p>Swift 5.8 also includes <em>conditional attributes</em> to reduce the maintenance cost of libraries that support multiple Swift tools versions. <code class="language-plaintext highlighter-rouge">#if</code> checks can now surround attributes on a declaration, and a new <code class="language-plaintext highlighter-rouge">hasAttribute(AttributeName)</code> conditional directive can be used to check whether the compiler version has support for the attribute with the name <code class="language-plaintext highlighter-rouge">AttributeName</code> in the current language mode:</p>

<div class="language-swift highlighter-rouge"><div class="highlight"><pre class="highlight"><code><span class="cp">#if hasAttribute(preconcurrency)</span>
<span class="kd">@preconcurrency</span>
<span class="cp">#endif</span>
<span class="kd">protocol</span> <span class="kt">P</span><span class="p">:</span> <span class="kt">Sendable</span> <span class="p">{</span> <span class="o">...</span> <span class="p">}</span>
</code></pre></div></div>

<p>Swift 5.8 brings other language and standard library enhancements, including <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0375-opening-existential-optional.md">unboxing for <code class="language-plaintext highlighter-rouge">any</code> arguments to optional parameters</a>, <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0373-vars-without-limits-in-result-builders.md">local wrapped properties in result builders</a>, <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0369-add-customdebugdescription-conformance-to-anykeypath.md">improved debug printing for key paths</a>, and more.</p>

<p>You can find the complete list of Swift Evolution proposals that were implemented in Swift 5.8 in the <a href="#swift-evolution-appendix">Swift Evolution Appendix</a> below.</p>

<h2 id="developer-experience">Developer Experience</h2>

<h3 id="improved-result-builder-implementation">Improved Result Builder Implementation</h3>

<p>The result builder implementation has been reworked in Swift 5.8 to greatly improve compile-time performance, code completion results, and diagnostics. The Swift 5.8 result builder implementation enforces stricter type inference that matches the semantics in <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md">SE-0289: Result Builders</a>, which has an impact on some existing code that relied on invalid type inference.</p>

<p>The new implementation takes advantage of the <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0326-extending-multi-statement-closure-inference.md">extended multi-statement closure inference</a> introduced in Swift 5.7 and applies the result builder transformation exactly as specified by the result builder proposal - a source-level transformation which is type-checked like a multi-statement closure. Doing so enables the compiler to take advantage of all the benefits of the improved closure inference for result builder-transformed code, including optimized type-checking performance (especially in invalid code) and improved error messages.</p>

<p>For more details, please refer to the <a href="https://forums.swift.org/t/improved-result-builder-implementation-in-swift-5-8/63192">Swift Forums post</a> that outlines the improvements and provides more information about invalid inference scenarios.</p>

<h2 id="ecosystem">Ecosystem</h2>

<h3 id="swift-docc">Swift-DocC</h3>

<p>As <a href="https://www.swift.org/blog/tspl-on-docc/">announced in February</a>, The Swift Programming Language book has been converted to Swift-DocC and made <a href="https://github.com/apple/swift-book">open source</a>, and with it came some enhancements to Swift-DocC itself in the form of <a href="https://www.swift.org/documentation/docc/options">option directives</a> you can use to change the behavior of your generated documentation. Swift-DocC has also added some new directives to create more <a href="https://www.swift.org/documentation/docc/api-reference-syntax#creating-custom-page-layouts">dynamic documentation pages</a>, including <a href="https://www.swift.org/documentation/docc/row">Grid-based layouts</a> and <a href="https://www.swift.org/documentation/docc/tab">tab navigators</a>.</p>

<p>To take things even further, you can now <a href="https://www.swift.org/documentation/docc/customizing-the-appearance-of-your-documentation-pages">customize the appearance of your documentation pages</a> with color, font, and icon customizations. Navigation also took a step forward with quick navigation, allowing fuzzy in-project search:</p>

<p><img src="/assets/images/5.8-blog/docc-fuzzy-search.png" alt="A DocC documentation page showing a quick navigation overlay showing fuzzy documentation search" /></p>

<p>Swift-DocC also now supports documenting extensions to types from other modules. This is an opt-in feature and can be <a href="https://apple.github.io/swift-docc-plugin/documentation/swiftdoccplugin/generating-documentation-for-extended-types">enabled by adding the <code class="language-plaintext highlighter-rouge">--include-extended-types</code> flag when using the Swift-DocC plugin</a>.</p>

<p><img src="/assets/images/5.8-blog/docc-extended-type.png" alt="A documentation page featuring an extension to the standard library's Collection type." /></p>

<h3 id="swift-package-manager">Swift Package Manager</h3>

<p>Following are some highlights from the changes introduced to the <a href="https://github.com/apple/swift-package-manager">Swift Package Manager</a> in Swift 5.8:</p>

<ul>
  <li>
    <p><a href="https://github.com/apple/swift-evolution/blob/main/proposals/0362-piecemeal-future-features.md">SE-0362</a>: Targets can now specify the upcoming language features they require. <code class="language-plaintext highlighter-rouge">Package.swift</code> manifest syntax has been expanded with an API to include setting <code class="language-plaintext highlighter-rouge">enableUpcomingFeature</code> and <code class="language-plaintext highlighter-rouge">enableExperimentalFeature</code> flags at the target level.</p>
  </li>
  <li>
    <p><a href="https://github.com/apple/swift-evolution/blob/main/proposals/0378-package-registry-auth.md">SE-0378</a>: Token authentication when interacting with a package registry is now supported. The <code class="language-plaintext highlighter-rouge">swift package-registry</code> command has two new subcommands <code class="language-plaintext highlighter-rouge">login</code> and <code class="language-plaintext highlighter-rouge">logout</code> for adding/removing registry credentials.</p>
  </li>
  <li>
    <p>Exposing an executable product that consists solely of a binary target that is backed by an artifact bundle is now allowed. This allows vending binary executables as their own separate package, independently of the plugins that are using them.</p>
  </li>
  <li>
    <p>In packages using tools version 5.8 or later, Foundation is no longer implicitly imported into package manifests. If Foundation APIs are used, the module needs to be imported explicitly.</p>
  </li>
</ul>

<p>See the <a href="https://github.com/apple/swift-package-manager/blob/main/CHANGELOG.md#swift-58">Swift Package Manager changelog</a> for the complete list of changes.</p>

<h3 id="swiftsyntax">SwiftSyntax</h3>

<p>With the Swift 5.8-aligned release of <a href="https://github.com/apple/swift-syntax">SwiftSyntax</a>, SwiftSyntax contains a completely re-written parser that is implemented entirely in Swift instead of relying on the C++ parser to produce a SwiftSyntax tree. While the Swift compiler still uses the old parser implemented in C++, the eventual goal is to replace the old parser entirely. The new parser has a number of advantages:</p>

<ul>
  <li>Contributing to or depending on SwiftSyntax is now as easy as any other Swift package. This greatly lowers the barrier of entry for new contributors and adopters.</li>
  <li>The new parser has been designed with error recovery as a primary goal. It is more tolerant of parsing errors and produces better error messages.</li>
  <li>SwiftSyntaxBuilder allows generating source code in a declarative way using a mixture of result builders and string interpolation. An example can be found <a href="https://github.com/apple/swift-syntax/blob/release/5.8/Examples/CodeGenerationUsingSwiftSyntaxBuilder.swift">here</a>.</li>
</ul>

<h3 id="windows-platform">Windows Platform</h3>

<p>Swift 5.8 continues the incremental improvements to the Windows toolchain. Some of the important work that has gone into this release cycle includes:</p>

<ul>
  <li>The Windows toolchain has reduced some of its dependency on environment variables. <code class="language-plaintext highlighter-rouge">DEVELOPER_DIR</code> was previously needed to locate components and this is no longer required. This cleans up the installation and enables us to get closer to per-user installation.</li>
  <li>ICU has been changed to static linking. This reduces the number of files that need to be distributed and reduces the number of dependencies that a shipping product requires. This was made possible by the removal of the ICU dependency in the Swift standard library.</li>
  <li>Some of the initial work to support C++ interop on Windows has been merged and is available in the toolchain. This includes the work towards modularising the Microsoft C++ Runtime (msvcprt).</li>
  <li>The <code class="language-plaintext highlighter-rouge">vcruntime</code> module has been renamed to <code class="language-plaintext highlighter-rouge">visualc</code>. This better reflects the module and paves the road for future enhancements for bridging the Windows platform libraries.</li>
  <li>A significant amount of work for improving path handling in the Swift Package Manager has been merged. This should help make Swift Package Manager more robust on Windows and improve interactions with SourceKit-LSP.</li>
  <li>SourceKit-LSP has benefited from several robustness improvements. Cross-module references are now more reliable and C/C++ references have been improved thanks to the enhanced path handling in SwiftPM which ensures that files are correctly identified.</li>
</ul>

<h2 id="downloads">Downloads</h2>

<p>Official binaries are <a href="https://swift.org/download/">available for download</a> from <a href="http://swift.org/">Swift.org</a> for Xcode, Windows, and Linux. The Swift 5.8 compiler is also included in <a href="https://apps.apple.com/app/xcode/id497799835">Xcode 14.3</a>.</p>

<h2 id="swift-evolution-appendix">Swift Evolution Appendix</h2>

<p>The following language, standard library, and Swift Package Manager proposals were accepted through the <a href="https://github.com/apple/swift-evolution">Swift Evolution</a> process and <a href="https://apple.github.io/swift-evolution/#?version=5.8">implemented in Swift 5.8</a>.</p>

<p><strong>Language and Standard Library</strong></p>

<ul>
  <li>SE-0274: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0274-magic-file.md">Concise magic file names</a></li>
  <li>SE-0362: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0362-piecemeal-future-features.md">Piecemeal adoption of upcoming language improvements</a></li>
  <li>SE-0365: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0365-implicit-self-weak-capture.md">Allow implicit self for weak self captures, after self is unwrapped</a></li>
  <li>SE-0367: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0367-conditional-attributes.md">Conditional compilation for attributes</a></li>
  <li>SE-0368: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0368-staticbigint.md">StaticBigInt</a></li>
  <li>SE-0369: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0369-add-customdebugdescription-conformance-to-anykeypath.md">Add CustomDebugStringConvertible conformance to AnyKeyPath</a></li>
  <li>SE-0370: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0370-pointer-family-initialization-improvements.md">Pointer Family Initialization Improvements and Better Buffer Slices</a></li>
  <li>SE-0372: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0372-document-sorting-as-stable.md">Document Sorting as Stable</a></li>
  <li>SE-0373: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0373-vars-without-limits-in-result-builders.md">Lift all limitations on variables in result builders</a></li>
  <li>SE-0375: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0375-opening-existential-optional.md">Opening existential arguments to optional parameters</a></li>
  <li>SE-0376: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0376-function-back-deployment.md">Function Back Deployment</a></li>
</ul>

<p><strong>Swift Package Manager</strong></p>

<ul>
  <li>SE-0362: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0362-piecemeal-future-features.md">Piecemeal adoption of upcoming language improvements</a></li>
  <li>SE-0378: <a href="https://github.com/apple/swift-evolution/blob/main/proposals/0378-package-registry-auth.md">Package Registry Authentication</a></li>
</ul>
"""

  @MainActor
  static let content: NSAttributedString = HTMLTools.convert(Self.htmlString, baseURL: URL(string: "https://swift.org"))!

  static let feed: ParsedFeed = {
    let filePath = URL(string: #filePath)!
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Tests/RSSTests/HTMLToolsTests/swift-org--atom.xml")
      .absoluteString

    let string = try! String(contentsOfFile: filePath)

    return try! FeedParser.parse(
      ParserData(url: "https://www.swift.org/atom.xml",
                 data: string.data(using: .utf8)!)
    )!
  }()

  static let item: ParsedItem = { Self.feed.items.first! }()
}
#endif
