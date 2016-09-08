# Changelog

## [0.4.0](https://github.com/amco/enhance/releases/tag/0.4.0)

* Update to CocoaPods 1.x Podfile in the Example app
* Build Example app with Xcode 8, along with associated changes to project files
* Fix broken overlay color assignment in Example app

## [0.3.1](https://github.com/amco/enhance/releases/tag/0.3.1)

* Allow color of overlay layer between background and image to be customized.

## [0.3.0](https://github.com/amco/enhance/releases/tag/0.3.0)

* Removed the storyboard that holds the image and scroll view. It was nice to keep view code in the storyboard but it caused more pain than was worth supporting. CocoaPods `0.36.x` broke something about how I handled resources and getting them into Pods. C'est la vie!

## [0.2.1](https://github.com/amco/enhance/releases/tag/0.2.1)

* Made `dismiss:` in [`ENHViewController.h`](https://github.com/amco/enhance/blob/653b817edd0d4ab623455dd503a52d3d4249062e/Pod/Classes/ENHViewController.h#L145) public

## [0.2.0](https://github.com/amco/enhance/releases/tag/0.2.0)

* Removed fallback to present in the key `UIWindow`. Must now initialize `enhance` with a view controller which will be used during presentation. ([64247d985](https://github.com/amco/enhance/commit/64247d9855448d39274651f7ea42863ba8b1bf56))
* Removed `showImage:fromView:inViewController:` and `showImageFromURL:fromView:inViewController`. ([53281725](https://github.com/amco/enhance/commit/5328172584614496c42b1b8141f1005df58cbbcc))
* Moved save/control menu out of pod and into example app. ([aa0116acc](https://github.com/amco/enhance/commit/aa0116accaabf31f111bebcd55db2c4ce2f67c37))
* Moved localizations to appropriate projects.
 ([3aa3c3dd2](https://github.com/amco/enhance/commit/3aa3c3dd2b11885108684876d20d01de711d2ea0))

## [0.1.0](https://github.com/amco/enhance/releases/tag/0.1.0)

* Initial release
