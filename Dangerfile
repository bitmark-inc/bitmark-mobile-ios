import Danger
let danger = Danger()

var bigPRThreshold = 1200;
if (danger.github.pullRequest.additions + danger.github.pullRequest.deletions > bigPRThreshold) {
  warn('> Pull Request size seems relatively large. If this Pull Request contains multiple changes, please split each into separate PR will helps faster, easier review.');
}

SwiftLint.lint(inline: true)