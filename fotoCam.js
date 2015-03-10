/**
 * fotoCam v1.0 
 * Webcam library for capturing JPEG & PNG images and submitting
 * to a server and saving to the system
 * http://labs.yapi.com/projects/fotoCam
 *
 * Yapi Inc - http://facebook.com/yapiLabs
 * Copyright (C) 2011 Yapi Labs
 * licensed under the MIT license.
 *
 * @author: Stanley Ilukhor - stan nesi (stannesi@yahoo.com)
 * @website: http://twitter.com/stannesi,
 *           http://facebook.com/stannesi
 *
 * Date: 27-08-2011 09:52:21 - (Sat, 27 Aug 2011)
 * For full documented source contact ambit
 *
 * file: fotoCam.js
*/

/**
  * @namespace Yapi public namespace for fotoCam webcam
  */
Yapi = window.Yapi || {};

/* first, a few dependencies */

(function() {
	if( Yapi && Yapi.fotoCam ) {
		// this is most likely to happen when people try to embed multiple
		// widgets on the same page and include this script again
		return;
	}

  /**
    * @constructor
    * Widget Base for new instances of the yooksvill Sharetronix Public/Profile widget
    * @param {Object} opts the configuration options for the widget
    */
	Yapi.fotoCam = function( opts ) {
		this.init( opts );
	}

  /**
    * static members
    */
	// The current version of FotoCam
	Yapi.fotoCam.version = "1.0 Beta";
	Yapi.fotoCam.instances = {};
	Yapi.fotoCam.uIdCount = 0;
	
	Yapi.fotoCam.prototype = function() {

		var version = "1.0",

		// Figure out what browser is being used.. if ie
		browser = function(){
			var ua = navigator.userAgent.toLowerCase();
			return {
				ie: ua.match(/MSIE\s([^;]*)/)
			};
		}();
		
		return {
			init: function( opts ) {
				var that = this;

				this._uid = ++Yapi.fotoCam.uIdCount
				//this._defaultOpts = {};			// a container where developers can place their own opts associated with this instance.
				this.opts = opts;
				this.eventQueue = [];
				this.cameraCore = null;

				this._isLoaded = false;
				this._isRendered = false;
				
				this._elmID = opts.id || 'yapi-fCam-' + this._uid;
				this._swfID = 'yapi-fCam-SWF-' + this._uid;
				
				// setup global control tracking
				Yapi.fotoCam.instances[this._swfID] = this;
				
				// load the option settings.
				this._initOpts();
				
				if ( !document.getElementById(this.opts.id) ) {
	            	document.write( '<div class="yapi-fCam" id="' + this._elmID + '"></div>' );
				}
				
				this._cameraElm = document.getElementById( this._elmID );
				
				this.setDimension( this.opts.camWidth, this.opts.camHeight );

				return this;
			},
			
			/**
			  * @private: _initOpts
			  * Private: initSettings ensures that all the
			  * settings are set, getting a default value if one was not assigned.
			  */
			_initOpts: function() {
				this.checkOpts = function( name, val, cb) {
					if (!cb)
						this.opts[name] = (!this.opts[name]) ? val : this.opts[name];
					else
						this.opts[cb][name] = (!this.opts[cb][name]) ? val : this.opts[cb][name];
				};

				// id of div element that holds the camera SWF object
				this.checkOpts('id', this._elmID);

				// camera settings
				this.checkOpts('bandwidth', 0);					// camera width - 0 for unlimited
				this.checkOpts('camWidth', 320);				// camera width
				this.checkOpts('camHeight', 240);				// camera height
				this.checkOpts('camFPS', 30);					// camera Frame Per Seconds (FPS)
				this.checkOpts('camQuality', 100);				// camera quality

				// photo settings
				this.checkOpts('photoWidth', 320);				// photo width
				this.checkOpts('photoHeight', 240);				// photo height
				this.checkOpts('photoQuality', 90);				// photo quality default - 90

				// urls and paths
				this.checkOpts('swfURL', 'fotoCam.swf');		// flash swf url
				this.checkOpts('soundURL', 'shutter.mp3');		// shutter sound url
				this.checkOpts('uploadURL', 'upload.php');		// url to upload file
				this.checkOpts('fileName', 'image.jpg');		// path to save image file
				
				this.checkOpts('soundEnabled', true);			// enable sound
				this.checkOpts('flashEnabled', true);			// enable flash
				this.checkOpts('stealthEnabled', true);			// enable stealth
				this.checkOpts('settingsEnabled', true);		// enable adobe flash settings
				
				// debug settings
				this.checkOpts('debug', true);
				
				// callbacks
				this.checkOpts('callbacks', {});

				// event handlers
				this.checkOpts('onCameraReady', null, 'callbacks');
				this.checkOpts('onCameraError', null, 'callbacks');
				
				this.checkOpts('onSnapStart', null, 'callbacks');
				this.checkOpts('onSnapError', null, 'callbacks');
				this.checkOpts('onSnapSuccess', null, 'callbacks');
				this.checkOpts('onSnapComplete', null, 'callbacks');

				this.checkOpts('onUploadStart', null, 'callbacks');
				this.checkOpts('onUploadError', null, 'callbacks');
				this.checkOpts('onUploadProgress', null, 'callbacks');
				this.checkOpts('onUploadSuccess', null, 'callbacks');
				this.checkOpts('onUploadComplete', null, 'callbacks');

				this.checkOpts('onSaveStart', null, 'callbacks');
				this.checkOpts('onSaveError', null, 'callbacks');
				this.checkOpts('onSaveProgress', null, 'callbacks');
				this.checkOpts('onSaveSuccess', null, 'callbacks');
				this.checkOpts('onSaveComplete', null, 'callbacks');

				this.checkOpts('onDebug', this.debugMessage, 'callbacks');				

				// update the swf url if needed
				if (!!this.opts.swfCaching) {
					this.opts.swfURL = this.opts.swfURL + (this.opts.swfURL.indexOf("?") < 0 ? "?" : "&") + "cachebust=" + new Date().getTime();
				}
				
				delete this.checkOpts;
			},

			/**
			  * @private: _getCameraCore
			  * retrieves the DOM reference to the Flash SWF element added by FotoCam 
			  * The element is cached after the first lookup
			  */
			_getCameraCore: function() {
				// get reference to flash sprite object/embed in DOM
				if (!this._isLoaded) {
					throw "FotoCam Error: SWF Flash is not loaded yet.";
					return;
				}
					
				if (!this.cameraCore)
					this.cameraCore = document.getElementById(this._swfID);
					
				if (!this.cameraCore)
					throw "FotoCam Error: Cannot locate camera 'cameraCore' SWF in DOM";
				
				return this.cameraCore;
			},

			/**
			  * @private: setDimension
			  * to set the dimension of the Flash SWF Movie
			  */
			setDimension: function( w, h ) {
				this.cwh = (w && h) ? [w, h] : [320, 240]; // default w/h if none provided
				return this;
			},
	
			/**
			  * @private: _buildOptsString
			  * takes the name/value pairs in the this.opts object and joins
			  * them up in to a string formatted "name=value&amp;name=value"
			  */
			_buildOptsString: function() {
				var aOpts = this.opts;
				var aOptsPairs = [];
				
				if (typeof(aOpts) === "object") {
					for (var name in aOpts) {
						if (aOpts.hasOwnProperty(name)) {
							aOptsPairs.push(encodeURIComponent(name.toString()) + "=" + encodeURIComponent(aOpts[name].toString()));
						}
					}
				}
			
				return aOptsPairs.join("&amp;");
			},

			/**
			  * @private: _getHtml
			  * generates the object tag needed to embed the flash swf in to the document
			  */			
			_getHtml: function() {
				var params = ['<param name="movie" value="', this.opts.swfURL, '" />',
							'<param name="allowScriptAccess" value="always">',
							'<param name="quality" value="high" />',
							'<param name="wmode" value="opaque" />',
							'<param name="menu" value="false" />',
							'<param name="bgcolor" value="#cccccc" />',
							'<param name="flashvars" value="', this._getFlashVars(), '" />'].join("");

				if (browser.ie) {
					var html = ['<object id="', this._swfID, '" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000',
								'" width="', this.cwh[0], '" height="', this.cwh[1], '">', params,
				  				'</object>'].join("");
				} else {
					var html = ['<object id="', this._swfID, '" type="application/x-shockwave-flash" data="', this.opts.swfURL,
								'" width="', this.cwh[0], '" height="', this.cwh[1], '">', params,
					  			'</object>'].join("");
				}

				return html;
			},

			/**
			  * @private: _getFlashVars
			  * builds the parameter string that will be passed to flash in the flashvars param.
			  */
			_getFlashVars: function() {
				// Build the parameter string
				return ["swfID=", encodeURIComponent(this._swfID),
						"&amp;bandwidth=", encodeURIComponent(this.opts.bandwidth),				
						"&amp;camWidth=", encodeURIComponent(this.opts.camWidth),
						"&amp;camHeight=", encodeURIComponent(this.opts.camHeight),
						"&amp;camFPS=", encodeURIComponent(this.opts.camFPS),
						"&amp;camQuality=", encodeURIComponent(this.opts.camQuality),
						
						"&amp;photoWidth=", encodeURIComponent(this.opts.photoWidth),
						"&amp;photoHeight=", encodeURIComponent(this.opts.photoHeight),
						"&amp;photoQuality=", encodeURIComponent(this.opts.photoQuality),
						
//						"&amp;swfURL=", encodeURIComponent(this.opts.swfURL),
						"&amp;soundURL=", encodeURIComponent(this.opts.soundURL),
						"&amp;uploadURL=", encodeURIComponent(this.opts.uploadURL),
						"&amp;fileName=", encodeURIComponent(this.opts.fileName),

						"&amp;debug=", encodeURIComponent(this.opts.debug),
						
						"&amp;soundEnabled=", encodeURIComponent(this.opts.soundEnabled),
						"&amp;flashEnabled=", encodeURIComponent(this.opts.flashEnabled),
						"&amp;stealthEnabled=", encodeURIComponent(this.opts.stealthEnabled),
						"&amp;settingsEnabled=", encodeURIComponent(this.opts.settingsEnabled)
					].join("");
			},

			/**
			  * @public: render
			  * function to render Flash SWF camera object to the document
			  */
			render: function() {

				var that = this;
				
				this._cameraElm.innerHTML = this._getHtml();

				this._isRendered = true;

				return this;
			},
			
			/**
			  * @public: destroy
			  * used to remove a FotoCam instance from the page. This method strives to remove
			  * all references to the SWF, and other objects so memory is properly freed.
			  * returns true if everything was destroyed. Returns a false if a failure occurs leaving FotoCam in an inconsistant state.
			  */
			  destroy: function() {
				try {
					// make sure Flash SWF is done before we try to remove it
					//this.stopUpload(null, false);
					//this.stopSave(null, false);					

					// remove the SWFUpload DOM nodes
					var cameraCore = null;
					cameraCore = this._getCameraCore();

					if (cameraCore && typeof(cameraCore.CallFunction) === "unknown") { // We only want to do this in IE
						// loop through all the SWF's properties and remove all function references (DOM/JS IE 6/7 memory leak workaround)
						for (var i in cameraCore) {
							try {
								if (typeof(cameraCore[i]) === "function") {
									cameraCore[i] = null;
								}
							} catch (ex) {}
						}
			
						// remove the SWF Element from the page
						try {
							cameraCore.parentNode.removeChild(cameraCore);
						} catch (ex) {}
					}

					// remove IE form fix reference
					window[this._swfID] = null;
			
					// destroy other references
					Yapi.fotoCam.instances[this._swfID] = null;
					delete Yapi.fotoCam.instances[this._swfID];
			
					this.cameraCore = null;
					this.opts = null;
					this.customSettings = null;
					this.eventQueue = null;
					this._uid = null;
					this._swfID = null;
					this._elmID = null;
					this._cameraElm = null;

					this._isLoaded = false;
					this._isRendered = false;
					
					return true;
				} catch (ex2) {
					return false;
				}
			},

			/**
			  * @public: destroy
			  * used to remove a FotoCam instance from the page. This method strives to remove
			  * all references to the SWF, and other objects so memory is properly freed.
			  * returns true if everything was destroyed. Returns a false if a failure occurs leaving FotoCam in an inconsistant state.
			  */
			printDebugInfo: function() {
				this.debug(
					[
						"---FotoCam Instance Info---\n",
						"Version: ", Yapi.fotoCam.version, "\n",
						"SWF ID: ", this._swfID, "\n",

						"Settings:\n",
						"\t", "bandwidth:                ", this.opts.bandwidth, "\n",

						"\t", "camWidth:                 ", this.opts.camWidth, "\n",
						"\t", "camHeight:                ", this.opts.camHeight, "\n",
						"\t", "camFPS:                   ", this.opts.camFPS, "\n",
						"\t", "camQuality:               ", this.opts.camQuality, "\n",

						"\t", "photoWidth:               ", this.opts.photoWidth, "\n",
						"\t", "photoHeight:              ", this.opts.photoHeight, "\n",
						"\t", "photoQuality:             ", this.opts.photoQuality, "\n",
						
						"\t", "swfURL:                   ", this.opts.swfURL, "\n",
						"\t", "soundURL:                 ", this.opts.soundURL, "\n",
						"\t", "uploadURL:                ", this.opts.uploadURL, "\n",
						"\t", "fileName:                 ", this.opts.fileName, "\n",

						"\t", "soundEnabled:             ", this.opts.soundEnabled.toString(), "\n",
						"\t", "flashEnabled:             ", this.opts.flashEnabled.toString(), "\n",
						"\t", "stealthEnabled:           ", this.opts.stealthEnabled.toString(), "\n",
						"\t", "settingsEnabled:          ", this.opts.settingsEnabled.toString(), "\n",

						"\t", "debug:                    ", this.opts.debug.toString(), "\n",
			
						"\t", "swfCaching:               ", this.opts.swfCaching.toString(), "\n",
			
						"Event Handlers:\n",
						"\t", "onCameraReady assigned:   ", (typeof this.opts.callbacks.onCameraReady === "function").toString(), "\n",
						"\t", "onCameraError assigned:   ", (typeof this.opts.callbacks.onCameraError === "function").toString(), "\n",
						
						"\t", "onSnapStart assigned:     ", (typeof this.opts.callbacks.onSnapStart === "function").toString(), "\n",
						"\t", "onSnapError assigned:     ", (typeof this.opts.callbacks.onSnapError === "function").toString(), "\n",
						"\t", "onSnapSuccess assigned:   ", (typeof this.opts.callbacks.onSnapSuccess === "function").toString(), "\n",
						"\t", "onSnapComplete assigned:  ", (typeof this.opts.callbacks.onSnapComplete === "function").toString(), "\n",
						
						"\t", "onUploadStart assigned:     ", (typeof this.opts.callbacks.onUploadStart === "function").toString(), "\n",
						"\t", "onUploadError assigned:     ", (typeof this.opts.callbacks.onUploadError === "function").toString(), "\n",
						"\t", "onUploadProgress assigned:  ", (typeof this.opts.callbacks.onUploadProgress === "function").toString(), "\n",
						"\t", "onUploadSuccess assigned:   ", (typeof this.opts.callbacks.onUploadSuccess === "function").toString(), "\n",
						"\t", "onUploadComplete assigned:  ", (typeof this.opts.callbacks.onUploadComplete === "function").toString(), "\n",
						
						"\t", "onSaveStart assigned:       ", (typeof this.opts.callbacks.onSaveStart === "function").toString(), "\n",
						"\t", "onSaveError assigned:       ", (typeof this.opts.callbacks.onSaveError === "function").toString(), "\n",
						"\t", "onSaveProgress assigned:    ", (typeof this.opts.callbacks.onSaveProgress === "function").toString(), "\n",
						"\t", "onSaveSuccess assigned:     ", (typeof this.opts.callbacks.onSaveSuccess === "function").toString(), "\n",
						"\t", "onSaveComplete assigned:    ", (typeof this.opts.callbacks.onSaveComplete === "function").toString(), "\n",

						"\t", "onDebug assigned:             ", (typeof this.opts.callbacks.onDebug === "function").toString(), "\n"
					].join("")
				);
				
				return this;
			  },

			/**
			  * @private: _callFlash
			  * handles function calls made to the Flash SWF element.
			  * Calls are made with a setTimeout for some functions to work around
			  * bugs in the ExternalInterface library.
			  */
			_callFlash: function(fnName, aArgs) {
				aArgs = aArgs || [];

				cameraCore = this._getCameraCore();
				
				var retVal, retStr;
			
				// flash's method if calling ExternalInterface methods (code adapted from MooTools).
				try {
					retStr = cameraCore.CallFunction('<invoke name="' + fnName + '" returntype="javascript">' + __flash__argumentsToXML(aArgs, 0) + '</invoke>');
					retVal = eval(retStr);
				} catch (ex) {
					throw "Call to " + fnName + " failed " + ex;
				}
				
				// Unescape file post param values
				if (retVal != undefined && typeof retVal.post === "object") {
					retVal = this._unescapeFilePostParams(retVal);
				}

				return retVal;
			},

			/**
			  * @private: _callFlash
			  * unescapeFileParams is part of a workaround for a flash bug where objects passed through ExternalInterface cannot have
			  * properties that contain characters that are not valid for JavaScript identifiers. To work around this
			  * the Flash Component escapes the parameter names and we must unescape again before passing them along.
			  */
			_unescapeFilePostParams: function(file) {
				var reg = /[$]([0-9a-f]{4})/i;
				var unescapedPost = {};
				var uk;
			
				if (file != undefined) {
					for (var k in file.post) {
						if (file.post.hasOwnProperty(k)) {
							uk = k;
							var match;
							while ((match = reg.exec(uk)) !== null) {
								uk = uk.replace(match[0], String.fromCharCode(parseInt("0x" + match[1], 16)));
							}
							unescapedPost[uk] = file.post[k];
						}
					}
			
					file.post = unescapedPost;
				}
			
				return file;
			},

			/****************************************
			 * SWF Flash control methods
			 * your UI should use these to operate FotoCam
			****************************************/
			/**
			  * @private: snap
			  * takes the snapshoot
			  */
			snap: function() {
				  this._callFlash("snap");
				  return this;
			},

			/**
			  * @private: upload
			  * upload the snapshoot data to url
			  */
			upload: function() {
				  this._callFlash("upload");
				  return this;
			},
			  
			/**
			  * @private: stopUpload
			  * stop uploading
			  */
			stopUpload: function() {
				  this._callFlash("stopUpload");
				  return this;
			},

			/**
			  * @private: save
			  * causing a file save dialog window to appear
			  * for saving image to file on local drive
			  */
			save: function() {
				  this._callFlash("save");
				  return this;
			},
			  
			/**
			  * @private: stopSave
			  * cancel saving
			  */
			stopSave: function() {
				  this._callFlash("stopSave");
				  return this;
			},

			/**
			  * @private: reset
			  * reset and prepare camera for another snap
			  */
			reset: function() {
				  this._callFlash("reset");
				  return this;
			},
			  
			/**
			  * @private: showSettings
			  * show flash cbamera settings dialog
			  */
			showSettings: function() {
				this._callFlash("showSettings");
				return this;
			},

			/**
			  * @private: setInfoText
			  * set camera Info Text (string)
			  */
			setInfoText: function(str) {
				this._callFlash("setInfoText", [str]);
				return this;
			},

			/**
			  * @private: setInfoTextStyle
			  * set camera Info Text style (string)
			  */
			setInfoTextStyle: function(str) {
				this._callFlash("setInfoTextStyle", [str]);
				return this;
			},

			/**
			  * @private: setBandwidth
			  * set camera bandwidth (value)
			  */
			setBandwidth: function(v) {
				this._callFlash("setBandwidth", [v]);
				return this;
			},

			/**
			  * @private: getBandwidth
			  * get camera bandwidth
			  */
			getBandwidth: function() {
				return this._callFlash("getBandwidth");
			},

			/**
			  * @private: setCamDimension
			  * set camera dimension (width , height)
			  */
			setCamDimension: function(w, h) {
				this._callFlash("setCamDimension", [w, h]);
				return this;
			},

			/**
			  * @private: getCamDimension
			  * get camera dimension object{width , height}
			  */
			getCamDimension: function() {
				return this._callFlash("getCamDimension");
			},

			/**
			  * @private: setCamFPS
			  * set camera FPS Frames per seconds (value)
			  */
			setCamFPS: function(v) {
				this._callFlash("setCamFPS", [v]);
				return this;
			},


			/**
			  * @private: getCamFPS
			  * get camera FPS Frames per seconds
			  */
			getCamFPS: function() {
				return this._callFlash("getCamFPS");
			},

			/**
			  * @private: setCamFPS
			  * set camera quality
			  */
			setCamQuality: function(v) {
				this._callFlash("setCamQuality", [v]);
				return this;
			},

			/**
			  * @private: getCamQuality
			  * get camera quality
			  */
			getCamQuality: function() {
				return this._callFlash("getCamQuality");
			},

			/**
			  * @private: setPhotoDimension
			  * set photo dimension (width , height)
			  */
			setPhotoDimension: function(w, h) {
				this._callFlash("setPhotoDimension", [w, h]);
				return this;
			},

			/**
			  * @private: getPhotoDimension
			  * get photo dimension object{width , height}
			  */
			getPhotoDimension: function() {
				return this._callFlash("getPhotoDimension");
			},


			/**
			  * @private: setPhotoQuality
			  * set photo quality
			  */
			setPhotoQuality: function(v) {
				this._callFlash("setPhotoQuality", [v]);
				return this;
			},

			/**
			  * @private: getPhotoQuality
			  * get photo quality
			  */
			getPhotoQuality: function() {
				return this._callFlash("getPhotoQuality");
			},

			/**
			  * @private: setSoundURL
			  * set sound URL
			  */
			setSoundURL: function(url) {
				this._callFlash("setSoundURL", [url]);
				return this;
			},

			/**
			  * @private: getSoundURL
			  * get sound URL
			  */
			getSoundURL: function() {
				return this._callFlash("getSoundURL");
			},

			/**
			  * @private: setUploadURL
			  * set upload URL
			  */
			setUploadURL: function(url) {
				this._callFlash("setUploadURL", [url]);
				return this;
			},

			/**
			  * @private: getSoundURL
			  * get upload URL
			  */
			getUploadURL: function() {
				return this._callFlash("getUploadURL");
			},

			/**
			  * @private: setFileName
			  * set file path
			  */
			setFileName: function(path) {
				this._callFlash("setFileName", [path]);
				return this;
			},

			/**
			  * @private: getFileName
			  * get file path
			  */
			getFileName: function() {
				return this._callFlash("getFileName");
			},

			/**
			  * @private: toggleSound
			  * toggle camera sound on/off
			  */
			toggleSound: function() {
				return this._callFlash("toggleSound");
			},

			/**
			  * @private: toggleFlash
			  * toggle camera flash on/off
			  */
			toggleFlash: function() {
				return this._callFlash("toggleFlash");
			},

			/**
			  * @private: toggleStealth
			  * toggle camera stealth on/off
			  */
			toggleStealth: function() {
				return this._callFlash("toggleStealth");
			},

			/**
			  * @private: selectCamera
			  * select camera device
			  */
			selectCamera: function() {
				return this._callFlash("selectCamera");
			},

			/**
			  * @private: testSound
			  * test camera sound
			  */
			testSound: function() {
				this._callFlash("testSound");
				return this;
			},

			/**
			  * @private: testFlash
			  * test camera flash
			  */
			testFlash: function() {
				this._callFlash("testFlash");
				return this;
			},

			/****************************************
			 * SWF Flash Event Interfaces
			 * these functions are used by Flash to trigger the various Events.
			 * all these functions a Private.
			 *
			 * because the ExternalInterface library is buggy the event calls
			 * are added to a queue and the queue then executed by a setTimeout.
			 * this ensures that events are executed in a determinate order and that
			 * the ExternalInterface bugs are avoided.
			****************************************/

			/**
			  * @private: _bqueueEvent
			  */
			_queueEvent: function(handlerName, aArgs) {
				// warning: don't call this.debug inside here or you'll create an infinite loop
				if (aArgs == undefined) {
					aArgs = [];
				} else if (!(aArgs instanceof Array)) {
					aArgs = [aArgs];
				}
				
				var that = this;
				if (typeof this.opts.callbacks[handlerName] === "function") {
					// Queue the event
					this.eventQueue.push(function () {
						this.opts.callbacks[handlerName].apply(this, aArgs);
					});
					
					// Execute the next queued event
					setTimeout(function () {
						that._executeNextEvent();
					}, 0);b
					
				} else if (this.opts.callbacks[handlerName] !== null) {
					throw "Event handler " + handlerName + " is unknown or is not a function";
				}
			},

			/**
			  * @private: snap
			  * causes the next event in the queue to be executed.  Since events are queued using a setTimeout
			  * we must queue them in order to garentee that they are executed in order.
			  */
			_executeNextEvent: function() {
				// warning: don't call this.debug inside here or you'll create an infinite loop
				var  fn = this.eventQueue ? this.eventQueue.shift() : null;
				if (typeof(fn) === "function") {
					fn.apply(this);
				}
			},

			/**
			  * @private: testExternalInterface
			  * called by Flash to see if JS can call in to Flash (test if External Interface is working)
			  */
			testExternalInterface: function () {
				try {
					return this._callFlash("TestExternalInterface");
				} catch (ex) {
					return false;
				}
			},

			/**
			  * @private: debug
			  * debug info
			  */
			debug: function(msg) {
				console.log(msg);
			},


			/****************************************
			 * SWF Flash User Callbacks
			****************************************/

			/**
			  * @private: onCameraReady
			  * this event is called by Flash when it has finished loading. Don't modify this.
			  * use the onCameraReady event setting to execute custom code when SWFUpload has loaded.
			  */
			onCameraReady: function () {
				this._isLoaded = true;
				// check that the movie element is loaded correctly with its ExternalInterface methods defined
				if (!this.cameraCore)
					cameraCore = this._getCameraCore();
	
				if (!cameraCore) {
					this.debug("Flash called back ready but the flash movie can't be found.");
					return;
				}
				
				this.cleanUp(cameraCore);
				this._queueEvent("onCameraReady");
			},

			/**
			  * @private: onCameraError
			  * this event is called by Flash when camera was not succeffully loaded or
			  * camera is unavailable
			  */
			onCameraError: function (message) {
				this._queueEvent("onCameraError", [message]);
			},

			/**
			  * @private: onSnapStart
			  * this event is called by Flash before snap shot is taken
			  */
			onSnapStart: function () {
				this._queueEvent("onSnapStart");
			},

			/**
			  * @private: onSnapError
			  * handle errors that occurs when an attempt to snap a shot fails
			  */
			onSnapError: function (message) {
				this._queueEvent("onSnapError", [message]);
			},

			/**
			  * @private: onSnapSuccess
			  * this event is called by Flash when snap shot is successfully taken
			  */
			onSnapSuccess: function () {
				this._queueEvent("onSnapSuccess");
			},

			/**
			  * @private: onSnapComplete
			  * this event is called by Flash when snapshot process has completed either successfully or failed
			  */
			onSnapComplete: function () {
				this._queueEvent("onSnapComplete");
			},

			/**
			  * @private: onUploadStart
			  * this event is called by Flash before upload
			  */
			onUploadStart: function () {
				this._queueEvent("onUploadStart");
			},

			/**
			  * @private: onUloadError
			  * handle errors that occurs when an error occur during uploading
			  */
			onUploadError: function (message) {
				this._queueEvent("onUploadError", [message]);
			},

			/**
			  * @private: onUploadProgress
			  * this event is called by Flash when upload is in progress
			  */
			onUploadProgress: function (bytesLoaded, bytesTotal) {
				this._queueEvent("onUploadProgress", [bytesLoaded, bytesTotal]);
			},

			/**
			  * @private: onUploadSuccess
			  * this event is called by Flash when upload is successfully
			  */
			onUploadSuccess: function (serverData) {
				this._queueEvent("onUploadSuccess", [serverData]);
			},

			/**
			  * @private: onUploadComplete
			  * this event is called by Flash when upload is completed either successfully or failed
			  */
			onUploadComplete: function () {
				this._queueEvent("onUploadComplete");
			},
		

			/**
			  * @private: onSaveStart
			  * this event is called by Flash before saving starts
			  */
			onSaveStart: function () {
				this._queueEvent("onSaveStart");
			},

			/**
			  * @private: onSaveError
			  * handle errors that occurs when an error occur during saving
			  */
			onSaveError: function (message) {
				this._queueEvent("onSaveError", [message]);
			},

			/**
			  * @private: onSaveProgress
			  * this event is called by Flash when saving is in progress
			  */
			onSaveProgress: function (bytesLoaded, bytesTotal) {
				this._queueEvent("onSaveProgress", [bytesLoaded, bytesTotal]);
			},

			/**
			  * @private: onSaveSuccess
			  * this event is called by Flash when saving is successfully
			  */
			onSaveSuccess: function () {
				this._queueEvent("onSaveSuccess");
			},

			/**
			  * @private: onSaveComplete
			  * this event is called by Flash when upload is completed either successfully or failed
			  */
			onSaveComplete: function () {
				this._queueEvent("onSaveComplete");
			},
	
			/**
			  * @private: cleanUp
			  * removes SWF Flash added fuctions to the DOM node to prevent memory leaks in IE.
			  * this function is called by Flash each time the ExternalInterface functions are created.
			  */
			cleanUp: function (cameraCore) {	
				// pro-actively unhook all the Flash functions
				try {
					if (this.cameraCore && typeof(cameraCore.CallFunction) === "unknown") { // We only want to do this in IE
						this.debug("removing flash functions hooks (this should only run in IE and should prevent memory leaks)");
						for (var key in cameraCore) {
							try {
								if (typeof(cameraCore[key]) === "function") {
									cameraCore[key] = null;
								}
							} catch (ex) {
							}
						}
					}
				} catch (ex1) {
				}
			
				//fix flashes own cleanup code so if the SWFMovie was removed from the page
				// it doesn't display errors.
				window["__flash__removeCallback"] = function (instance, name) {
					try {
						if (instance) {
							instance[name] = null;
						}
					} catch (flashEx) {

					}
				};
				
				return this;
			}
		};
	}();
})();