# Contributing

## Filing Issues

Whether you find a bug, typo or an API call that could be clarified, please [file an issue](https://github.com/happn-app/BMO/issues) on our GitHub repository.

When filing an issue, please provide as much of the following information as possible in order to help others fix it:

1. **Goals**
2. **Expected results**
3. **Actual results**
4. **Steps to reproduce**
5. **Code sample that highlights the issue** (full Xcode projects that we can compile ourselves are ideal)
6. **Version of BMO / Xcode / iOS / OSX**
7. **Version of involved dependency manager (SPM / Carthage)**

If you'd like to send us sensitive sample code to help troubleshoot your issue, you can email <oss@happn.com> directly.

### Speeding things up :runner:

You may just copy this little script below and run it directly in your project directory in **Terminal.app**. It will take of compiling a list of relevant data as described in points 6. and 7. in the list above. It copies the list directly to your pasteboard for your convenience, so you can attach it easily when filing a new issue without having to worry about formatting and we may help you faster because we don't have to ask for particular details of your local setup first.

```shell
echo "\`\`\`
$(sw_vers)

$(xcode-select -p)
$(xcodebuild -version)

$(which bash && bash -version | head -n1)

$(which carthage && carthage version)
$(test -e Cartfile.resolved && cat Cartfile.resolved | grep --color=no BMO || echo "(not in use here)")

$(which git && git --version)
\`\`\`" | tee /dev/tty | pbcopy
```

## Contributing Enhancements

We love contributions to BMO! If you'd like to contribute code, documentation, or any other improvements, please [file a Pull Request](https://github.com/happn-app/BMO/pulls) on our GitHub repository. Unit tests are highly appreciated for each of your contribution.

### Commit Messages

Below are some guidelines about the format of the commit message itself:

* Separate the commit message into a single-line title and a separate body that describes the change.
* Make the title concise to be easily read within a commit log.
* Make the body concise, while including the complete reasoning. Unless required to understand the change, additional code examples or other details should be left to the pull request.
* If the commit fixes a bug, include the number of the issue in the message.
* Use the first person infinitive tense - for example "Fix …" instead of "Fixes …" or "Fixed …".
* If the commit is a bug fix on top of another recently committed change, or a revert or reapply of a patch, include the Git revision number of the prior related commit, e.g. `Revert abcd3fg because it caused #1234`.

You can find our reference guidelines [here](https://chris.beams.io/posts/git-commit/).
