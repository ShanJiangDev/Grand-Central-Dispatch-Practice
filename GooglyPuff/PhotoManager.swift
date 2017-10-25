/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation

// Notification when new photo instances are added
let photoManagerContentAddedNotification = "com.raywenderlich.GooglyPuff.PhotoManagerContentAdded"
// Notification when content updates (i.e. Download finishes)
let photoManagerContentUpdatedNotification = "com.raywenderlich.GooglyPuff.PhotoManagerContentUpdated"

// Photo Credit: Devin Begley, http://www.devinbegley.com/
let overlyAttachedGirlfriendURLString = "http://i.imgur.com/UvqEgCv.png"
let successKidURLString = "http://i.imgur.com/dZ5wRtb.png"
let lotsOfFacesURLString = "http://i.imgur.com/tPzTg7A.jpg"

typealias PhotoProcessingProgressClosure = (_ completionPercentage: CGFloat) -> Void
typealias BatchPhotoDownloadingCompletionClosure = (_ error: NSError?) -> Void
/*
     Singleton
     Not thread safe: singletons are often used from multiple controllers accessing the singleton instance at the same time.
                     can only be run in one context at a time
     When cause thread unsafe:
         1. During initialization of the singleton instance (solved below by using two variable _sharedManager and sharedManager)
         2. During reads and writes to the instance.
*/
// To avoid the initialization be called concurrentelly(from two threads at once)
// _sharedManager is used to imitializ PhotoManager lazily. this happen only at the first access
private let _sharedManager = PhotoManager()

class PhotoManager {
    // Public variable below returns the private _sharedManager variable to ensure that this operation is thread safe.
  class var sharedManager: PhotoManager {
    // _sharedManager is used to imitializ PhotoManager lazily. this happen only at the first access
    // From here
    return _sharedManager
  }
  
  fileprivate var _photos: [Photo] = []
    // below -- read method -- modify array object
  var photos: [Photo] {
    // return a copy of the photos array -> passing by value results in a copy of the object and changes to the copy will not affect the original.
    // By default swift class instance are passed by reference and structs passed by value. Swift's built-in data types like Array and Dictionary, are implemented as structs
    
    // But this will not protect against one thread calling the write method while siultaneously another thread calls this read method
    return _photos
  }
  
    // It is not safe to let one thread modify the array while another is reading it.
    // below -- write method -- modify array object
  func addPhoto(_ photo: Photo) {
    _photos.append(photo)
    DispatchQueue.main.async {
      self.postContentAddedNotification()
    }
  }
  
  func downloadPhotosWithCompletion(_ completion: BatchPhotoDownloadingCompletionClosure?) {
    var storedError: NSError?
    for address in [overlyAttachedGirlfriendURLString,
                    successKidURLString,
                    lotsOfFacesURLString] {
                      let url = URL(string: address)
                      let photo = DownloadPhoto(url: url!) {
                        _, error in
                        if error != nil {
                          storedError = error
                        }
                      }
                      PhotoManager.sharedManager.addPhoto(photo)
    }
    
    completion?(storedError)
  }
  
  fileprivate func postContentAddedNotification() {
    NotificationCenter.default.post(name: Notification.Name(rawValue: photoManagerContentAddedNotification), object: nil)
  }
}
