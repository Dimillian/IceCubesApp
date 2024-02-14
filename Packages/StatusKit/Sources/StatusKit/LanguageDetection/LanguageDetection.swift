import Foundation
import NaturalLanguage

private func stripToPureLanguage(inText: String) -> String {
  let hashtagRegex = try! Regex("#[\\w]*")
  let emojiRegex = try! Regex(":\\w*:")
  let atRegex = try! Regex("@\\w*")

  var resultStr = inText

  for regex in [hashtagRegex, emojiRegex, atRegex] {
    let splitArray = resultStr.split(separator: regex, omittingEmptySubsequences: true)
    resultStr = splitArray.joined() as String
  }

  return resultStr.trimmingCharacters(in: .whitespacesAndNewlines)
}

func detectLanguage(text: String) -> String? {
  let recognizer = NLLanguageRecognizer()

  let strippedText = stripToPureLanguage(inText: text)

  recognizer.processString(strippedText)

  let hypotheses = recognizer.languageHypotheses(withMaximum: 1)

  // Use the detected language only with >= 85 % confidence
  if let (lang, confidence) = hypotheses.first, confidence >= 0.85 {
    return lang.rawValue
  } else {
    return nil
  }
}
