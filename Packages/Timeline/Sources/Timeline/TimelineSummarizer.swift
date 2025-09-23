#if canImport(FoundationModels)
import FoundationModels
import Models
import Observation


@Generable(description: "Brief text summary social media timeline items. When responding, do not use the term “the social media posts”. Consider starting with “What’s happening now”.")
struct TimelineSummary {
    @Guide(description: "Markdown formatted text that summarizes a number of social media timeline items.")
    var summary: String
    
    @Guide(description: "One or two word generalized topics that are relevant to the content of the social media timeline items. Most topics should only be one word. A minority should be two words. Examples: 'music', 'iOS development', 'San Francisco', 'politics', 'socializing', 'health', and so on.")
    var topics: [String]
}
#else
struct TimelineSummary {
    var summary = "NOT IMPLMEMENTED"
}
#endif
