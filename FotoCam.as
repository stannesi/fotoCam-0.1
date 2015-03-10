/*
* fotoCam v1.0
* copyright:	(c) Yapi Labs
*
* @author:		Stanley Ilukhor (stannesi)
*/
package
{
	import com.adobe.images.JPGEncoder;
	import com.yapi.fotocam.ExternalCall;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.ActivityEvent;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.media.Camera;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.Video;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.text.AntiAliasType;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	[SWF(width = "320", height = "240", framerate ="24", backgroundColor = "#000000")]
	
	public class FotoCam extends Sprite
	{
		private const version:String  = "v1.0 Beta";
		
		private var video:Video;
		private var camera:Camera;
		
		private var sound:Sound;
		private var soundChannel:SoundChannel;
		
		private var jpgEncoder:JPGEncoder;
		
		private var bmp:Bitmap;
		private var bmpData:BitmapData;
		
		private var uLoader:URLLoader;
		private var fileRef:FileReference;
		
		// text field vars
		private var txtCont:Sprite
		private var txtInfoText:String;
		private var txtInfoStyle:String;
		private var txtInfoField:TextField;
		
		// cam flash vars
		/*
		private var flashTween:Tween;
		private var flashRect:Shape;
		private var flashCont:Sprite
		*/
		
		// opts values passed in from the HTML
		private var opts:Object =  new Object();
		
		// state tracking
		private var trackSnapping:Boolean = false;
		private var trackUploading:Boolean = false;
		private var trackSaving:Boolean = false;
		
		// callbacks
		private var cbCameraReady:String;
		private var cbCameraError:String;
		
		private var cbSnapStart:String;
		private var cbSnapError:String;
		private var cbSnapSuccess:String;
		private var cbSnapComplete:String;
		
		private var cbUploadStart:String;
		private var cbUploadProgress:String;
		private var cbUploadError:String;
		private var cbUploadSuccess:String;
		private var cbUploadComplete:String;
		
		private var cbSaveDialogCancel:String;
		private var cbSaveStart:String;
		private var cbSaveProgress:String;
		private var cbSaveError:String;
		private var cbSaveSuccess:String;
		private var cbSaveComplete:String;
		
		private var cbDebug:String;
		private var cbTestExternalInterface:String;
		private var cbCleanUp:String;
		
		public function FotoCam()
		{
			/* do the feature detection.  Make sure this version of Flash
			* supports the features we need. If not abort initialization.
			*/
			if (!flash.net.FileReference || !flash.net.URLRequest || !flash.external.ExternalInterface || !flash.external.ExternalInterface.available) {
				return;
			}
			// allow uploading to any domain
			Security.allowDomain("*");
			
			//var flashVars:Object = LoaderInfo(this.root.loaderInfo).parameters;
			this.opts = LoaderInfo(this.root.loaderInfo).parameters;
			
			this.initOpts();
			
			this.setMaxDimension();
			
			this.setupStage();
			
			/* **Configure the callbacks**
			* The JavaScript tracks all the instances of fotoCam on a page.  We can access the instance
			* associated with this SWF file using the opts.swfID.  Each callback is accessible by making
			* a call directly to it on our instance.  There is no error handling for undefined callback functions.
			* A developer would have to deliberately remove the default functions,set the variable to null, or remove
			* it from the init function.
			*/
			this.cbCameraReady		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onCameraReady";
			this.cbCameraError		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onCameraError";
			
			this.cbSnapStart		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSnapStart";
			this.cbSnapError		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSnapError";
			this.cbSnapSuccess		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSnapSuccess";
			this.cbSnapComplete		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSnapComplete";
			
			this.cbUploadStart		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onUploadStart";
			this.cbUploadProgress	= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onUploadProgress";
			this.cbUploadError		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onUploadError";
			this.cbUploadSuccess	= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onUploadSuccess";
			this.cbUploadComplete	= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onUploadComplete";
			
			this.cbSaveDialogCancel = "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSaveDialogCancel";
			this.cbSaveStart		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSaveStart";
			this.cbSaveProgress		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSaveProgress";
			this.cbSaveError		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSaveError";
			this.cbSaveSuccess		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSaveSuccess";
			this.cbSaveComplete		= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].onSaveComplete";
			
			this.cbDebug			= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].debug";
			this.cbTestExternalInterface = "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].TestExternalInterface";
			this.cbCleanUp			= "Yapi.fotoCam.instances[\"" + this.opts.swfID + "\"].cleanUp";
			
			this.camera = this.getCamera();
			
			if (this.camera != null)
			{
				// load camera
				this.loadCamera();
				// load text field
				this.loadText();
				// load sound
				this.loadSound();
				// load flash
				this.loadFlash();
				// setup external callbacks for javascript 
				this.setupExternalCallbacks();
				
				this.debug("FotBoCam Init complete...");
				this.printDebugInfo();
				// call onCameraReady callback
				ExternalCall.simple(this.cbCameraReady);
			} else {
				// call onCameraError callback
				ExternalCall.error(this.cbCameraError, "Webcam is not available, you nebed a webcam...");
			}
		}
		
		private function initOpts():void
		{
			this.debug("init Opts...");
			// camera settings
			this.checkOpts("bandwidth", 0, true);			// camera width - 0 for unlimited
			
			this.checkOpts("camWidth", 320, true);			// camera width
			this.checkOpts("camHeight", 240, true);			// camera height
			this.checkOpts("camFPS", 30, true);				// camera Frame Per Seconds (FPS)
			this.checkOpts("camQuality", 100, true);			// camera quality
			
			// photo settings
			this.checkOpts("photoWidth", 950);			// photo width
			this.checkOpts("photoHeight", 750);			// photo height
			this.checkOpts("photoQuality", 90);			// photo quality default - 90
			
			// Info Text settings
			this.checkOpts("txtInfoText", ""); // text info text
			this.checkOpts("txtInfoStyle", "p{font-family: Arial, Helvetica, _sans; font-size: 11; font-weight: bold;}");			// text info style
			
			/*
			this.checkOpts("txtContWidth", 0);			// text info width
			this.checkOpts("txtContHeight", 0);			// text info height
			*/
			
			// urls and paths
			//this.checkOpts("swfURL", "fotoCam.swf");	// flash swf url
			this.checkOpts("soundURL", "shutter.mp3");	// shutter sound url
			this.checkOpts("uploadURL", "upload.php");	// url to upload file
			this.checkOpts("fileName", "image.jpg");	// path to save image file
			
			this.checkOpts('soundEnabled', true);		// enable sound
			this.checkOpts('flashEnabled', true);		// enable flash
			this.checkOpts('stealthEnabled', true);		// enable stealth
			//this.checkOpts('settingsEnabled', true);	// enable adobe flash settings
			
			// debug settings
			this.checkOpts('debug', true);
		}
		
		private function checkOpts(name:String, val:*, floor:Boolean = false):void
		{
			if (floor)
				this.opts[name] = (!this.opts[name]) ? Math.floor(val) : Math.floor(this.opts[name]);
			else {
				this.opts[name] = (!this.opts[name]) ? val : this.opts[name];
				
				if (this.opts[name] == "true")
					this.opts[name] = true;
				if (this.opts[name] == "false")
					this.opts[name] = false;
			}
		}
		
		// set max dimensition from camera and photo dimension
		private function setMaxDimension():void
		{
			this.opts.maxWidth = Math.max(this.opts.camWidth, this.opts.photoWidth);
			this.opts.maxHeight = Math.max(this.opts.camHeight, this.opts.photoHeight);
		}
		
		// set the stage
		private function setupStage():void
		{
			this.debug("setting stage...");
			this.stage.scaleMode = StageScaleMode.EXACT_FIT;
			this.stage.align = StageAlign.TOP_LEFT;
			this.stage.stageWidth = this.opts.maxWidth;
			this.stage.stageHeight = this.opts.maxHeight;
			this.stage.stageFocusRect = false;
		}
		
		// hack to auto-select iSight camera on Mac (JPEGCam Issue #5, submitted by manuel.gonzalez.noriega)		
		// from: http://www.squidder.com/2009/03/09/trick-auto-select-mac-isight-in-flash/
		private function getCamera():Camera
		{
			this.debug("getting Camera...");
			var iCam:int = -1;
			for (var i:uint = 0, len:int = Camera.names.length; i < len; i++)
			{
				if (Camera.names[i] == "USB Video Class Video") {
					iCam = i;
					i = len;
				}
			}
			if (iCam > -1)
				return Camera.getCamera(String(iCam));
			else
				return Camera.getCamera();
		}
		
		// load camera device
		private function loadCamera():void
		{
			this.debug("loading Camera...");
			
			var that:FotoCam = this;
			
			this.camera.addEventListener(StatusEvent.STATUS, function (event:StatusEvent):void {
				that.debug("Camera status handler: " + event);
			});
			
			this.camera.addEventListener(ActivityEvent.ACTIVITY, function (event:ActivityEvent):void {
				that.debug("camera activity handler: " + event);
			});
			
			this.camera.setQuality(this.opts.bandwidth, this.opts.camQuality);
			this.camera.setKeyFrameInterval(10);
			this.camera.setMode(this.opts.camWidth, this.opts.camHeight, this.opts.camFPS);
			
			// do not detect motion (may help reduce CPU usage)
			this.camera.setMotionLevel(100);
			
			this.video = new Video(this.opts.maxWidth, this.opts.maxHeight);
			this.video.smoothing = true;
			this.video.attachCamera(this.camera);
			
			if ((this.opts.camWidth < this.opts.photoWidth) && (this.opts.camHeight < this.opts.photoHeight))
			{
				this.video.scaleX = this.opts.camWidth / this.opts.photoWidth;
				this.video.scaleY = this.opts.camHeight / this.opts.photoHeight;
			}
			
			this.addChild(this.video);
		}
		
		// update camera device
		private function updateCameraDimension():void
		{
			this.debug("updating Camera...");
			
			this.camera.setQuality(this.opts.bandwidth, this.opts.camQuality);
			this.camera.setMode(this.opts.camWidth, this.opts.camHeight, this.opts.camFPS);
			
			this.video.width = this.opts.maxWidth;
			this.video.height = this.opts.maxHeight;
			
			if ((this.opts.camWidth < this.opts.photoWidth) && (this.opts.camHeight < this.opts.photoHeight))
			{
				this.video.scaleX = this.opts.camWidth / this.opts.photoWidth;
				this.video.scaleY = this.opts.camHeight / this.opts.photoHeight;
			}
		}
		
		// load text
		private function loadText():void
		{
			this.debug("loading text...");
			this.txtCont = new Sprite();
			this.txtInfoField = new TextField;
			
			this.txtInfoField.type = TextFieldType.DYNAMIC;
			this.txtInfoField.antiAliasType = AntiAliasType.ADVANCED;
			this.txtInfoField.cacheAsBitmap = true;
			this.txtInfoField.multiline = true;
			this.txtInfoField.wordWrap = false;
			this.txtInfoField.tabEnabled = false;
			this.txtInfoField.border = false;
			this.txtInfoField.selectable = false;
			this.txtInfoField.condenseWhite = true;
			
			this.txtInfoField.textColor = 0xffffff;
			this.setInfoTextStyle("p{font-family: Arial, Helvetica, _sans; font-size: 11; font-weight: bold;}");
			this.setInfoText("<p>click camera screen to save to computer</p>");
			
			this.txtInfoField.width = this.opts.camWidth;
			this.txtInfoField.y = this.opts.camHeight - 30 + 5;
			
			this.txtCont.alpha = 0.5;
			this.txtCont.graphics.beginFill(0x000000);
			this.txtCont.graphics.drawRect(0, this.opts.camHeight - 30, this.opts.camWidth, 30);
			
			this.txtInfoField.autoSize = TextFieldAutoSize.CENTER;
			this.txtCont.addChild(this.txtInfoField);
		}
		
		// load camera flash
		private function loadSound():void
		{
			this.debug("loading sound...");
			this.sound = new Sound();
			this.sound.load(new URLRequest(this.opts.soundURL));
		}
		
		// load camera flash
		private function loadFlash():void
		{
			/*
			this.debug("loading flash...");
			this.flashRect = new Shape();
			this.flashCont = new Sprite();
			
			this.flashRect.graphics.beginFill(0xffffff);
			this.flashRect.graphics.drawRect(0, 0, this.opts.camWidth, this.opts.camHeight);
			
			addChild(this.flashCont);
			*/
		}
		
		// called by JS to see if it can access the external interface
		private function TestExternalInterface():Boolean {
			return true;
		}
		
		
		/******************************************************************
		 * Upload FileReference Event Handlers
		 *******************************************************************/
		private function uploadOpenHandler(event:Event):void {
			this.debug("Event: uploadProgress (OPEN)");
			ExternalCall.simple(this.cbUploadProgress);
		}
		
		private function uploadProgressHandler(event:ProgressEvent):void {
			// On early than Mac OS X 10.3 bytesLoaded is always -1, convert this to zero. Do bytesTotal for good measure.
			//  http://livedocs.adobe.com/flex/3/langref/flash/net/FileReference.html#event:progress
			var bytesLoaded:Number = event.bytesLoaded < 0 ? 0 : event.bytesLoaded;
			var bytesTotal:Number = event.bytesTotal < 0 ? 0 : event.bytesTotal;
			
			this.debug("Event: uploadProgress: Bytes: " + bytesLoaded + ". Total: " + bytesTotal);
			ExternalCall.byteProgress(this.cbUploadProgress, bytesLoaded, bytesTotal);
		}
		
		private function uploadSecurityErrorHandler(event:SecurityErrorEvent):void {
			this.debug("Event: uploadError : Security Error : " + event.text);
			ExternalCall.error(this.cbUploadError, event.text);
			
			this.uploadComplete();
		}
		
		private function uploadHttpStatusHandler(event:HTTPStatusEvent):void {
			this.debug("Event: uploadHttpStatus : HTTP Status : " + event);
			ExternalCall.simple(this.cbUploadProgress);
			
			this.uploadComplete();
		}
		
		private function uploadCompleteHandler(event:Event):void {
			this.debug("Event Complete: uploadSuccess: Data: " + event.target.data);
			ExternalCall.uploadSuccess(this.cbUploadSuccess, event.target.data);
			
			this.uploadComplete();
		}
		
		/*
		private function uploadServerDataHandler(event:DataEvent):void {
		this.debug("Event DataEvent: uploadSuccess: Data: " + event.data);
		ExternalCall.uploadSuccess(this.cbUploadSuccess, event.data);
		
		this.uploadComplete();
		}
		*/
		private function uploadIOErrorHandler(event:IOErrorEvent):void {
			this.debug("Event: uploadError : IO Error: " + event.text);
			ExternalCall.error(this.cbUploadError, event.text);
			
			this.uploadComplete();
		}
		
		/******************************************************************
		 * Dialog click Handling Functions
		 *******************************************************************/
		private function saveClickHandler(e:MouseEvent):void {
			this.save();
		}
		
		
		/******************************************************************
		 * Save FileReference Event Handlers
		 *******************************************************************/
		private function saveOpenHandler(event:Event):void {
			this.debug("Event: saveProgress (OPEN)");
			ExternalCall.simple(this.cbSaveProgress);
		}
		
		private function saveCancelHandler(event:Event):void {
			this.debug("Event: SaveDialogCancel: save dialog box cancelled :" + event);
			ExternalCall.simple(this.cbSaveDialogCancel);
			this.saveComplete();
		}
		
		private function saveSelectHandler(event:Event):void {
			this.debug("Event: SaveProgress (SELECT) : selecting a file :" + event);
			ExternalCall.simple(this.cbSaveProgress);
		}
		
		private function saveCompleteHandler(event:Event):void {
			this.debug("Event: saveSuccess: Data: " + event);
			ExternalCall.simple(this.cbSaveSuccess);
			
			this.saveComplete();
		}
		
		private function saveProgressHandler(event:ProgressEvent):void {
			// On early than Mac OS X 10.3 bytesLoaded is always -1, convert this to zero. Do bytesTotal for good measure.
			//  http://livedocs.adobe.com/flex/3/langref/flash/net/FileReference.html#event:progress
			var bytesLoaded:Number = event.bytesLoaded < 0 ? 0 : event.bytesLoaded;
			var bytesTotal:Number = event.bytesTotal < 0 ? 0 : event.bytesTotal;
			
			this.debug("Event: saveProgress: Bytes: " + bytesLoaded + ". Total: " + bytesTotal);
			ExternalCall.byteProgress(this.cbSaveProgress, bytesLoaded, bytesTotal);
		}
		
		private function saveIOErrorHandler(event:IOErrorEvent):void {
			this.debug("Event: saveError : IO Error: " + event.text);
			ExternalCall.error(this.cbSaveError, event.text);
			
			this.saveComplete();
		}
		
		/******************************************************************
		 * Externally exposed functions
		 *******************************************************************/
		
		// snap function to take snapshot from camera
		private function snap():void
		{
			if (this.trackSnapping) {
				this.debug("Snap(): Snapshot already in progress. cannot start another snapshot.");
				return;
			}
			// reset camera view for another snapshot
			this.reset();
			
			this.debug("Snap: Snapshot ready to take shot.");
			
			// Trigger the snapStart event which will call snapShot to begin the actual snap shot
			this.debug("Event: snap : starting snapshot");
			ExternalCall.simple(this.cbSnapStart);
			
			this.trackSnapping = true;
			
			if (this.opts.flashEnabled) {
				this.debug("flash enabled: snap(): camera flashing");
				this.flashCamera();
			}
			
			if (this.opts.soundEnabled)
			{
				this.debug("sound enabled: snap(): camera sound");
				this.soundChannel = this.sound.play();
				setTimeout(this.snapShot, 10);
			} else {
				this.debug("sound disabled: snap(): camera sound");
				this.snapShot();
			}
		}
		
		private function snapShot():void
		{
			try {
				this.debug("snapshot: snap(): creating and drawing the bitmap data");
				this.bmpData =  new BitmapData(this.opts.maxWidth, this.opts.maxHeight);
				this.bmpData.draw(this.video);
				
				if (this.opts.stealthEnabled)
				{
					// draw snapshot on stage
					this.debug("snapshot: snap(): draw snapshot on stage");
					this.bmp = new Bitmap(this.bmpData);
					
					// resize to camera dimension if bmp is larger
					if ((this.bmp.width > this.opts.camWidth) && (this.bmp.height > this.opts.camHeight))
					{
						this.bmp.width = opts.camWidth;
						this.bmp.height = this.opts.camHeight;
					}
					
					this.addChild(this.bmp);
					
					// stop capturing video
					this.debug("snapshot: snap(): stop capturing video");
					this.video.attachCamera(null);
					this.removeChild(this.video);
					
					// enable saving mode show save Info text
					enableSaveMode();
				}
				
				this.trackSnapping = false;
				
				this.debug("snapshot: snap complete");
				ExternalCall.simple(this.cbSnapComplete);
				
				this.debug("snapshot: snap sucessful");
				ExternalCall.simple(this.cbSnapSuccess);
				
			} catch(ex:Error){
				var msg:String = ex.errorID + "\n" + ex.name + "\n" + ex.message + "\n" + ex.getStackTrace();
				this.debug("snapshot: snap(): Exception occurred: " + msg);
				
				this.trackSnapping = false;
				
				this.debug("event: snap error: " + msg);
				ExternalCall.error(this.cbSnapError, msg);
				
				this.debug("snapshot: snap complete");
				ExternalCall.simple(this.cbSnapComplete);
			}
		}
		
		private function enableSaveMode():void {
			this.debug("enabling saveMode...");
			var that:FotoCam = this;
			
			this.stage.addEventListener(MouseEvent.CLICK, function (event:MouseEvent):void {
				that.saveClickHandler(event);
			});
			
			this.addChild(this.txtCont);
		}
		
		private function disableSaveMode():void {
			this.debug("disabling saveMode...");
			var that:FotoCam = this;
			
			this.stage.removeEventListener(MouseEvent.CLICK, function (event:MouseEvent):void {
				that.saveClickHandler(event);
			});
			
			this.removeChild(this.txtCont);
		}
		
		// upload bitmap data to url for processing
		private function upload():void
		{
			if (this.trackUploading) {
				this.debug("upload(): upload already in progress. Not starting another upload.");
				return;
			}
			
			this.debug("upload: ready for uploading .");
			
			this.trackUploading = true;
			
			if (this.bmpData)
			{
				try {
					// Trigger the uploadStart event to begin the actual upload
					this.debug("event: UploadStart : starting upload");
					ExternalCall.simple(this.cbUploadStart);
					
					if ((this.opts.camWidth > this.opts.photoWidth) && (this.opts.camHeight > this.opts.photoHeight))
					{
						// resize image downward before submitting if camera dimension is greater
						this.debug("upload: resize image downward before submitting if camera dimension is greater");
						var tmpData:BitmapData = new BitmapData(this.opts.photoWidth, this.opts.photoHeight);
						
						var matrix:Matrix = new Matrix();
						matrix.scale(this.opts.photoWidth / this.opts.camWidth, this.opts.photoHeight / this.opts.camHeight);
						
						tmpData.draw(this.bmpData, matrix, null, null, null, true);
						this.bmpData = tmpData;
					}
					
					this.debug("upload: encoding to bitmap Data to Jpg");
					var byteArray:ByteArray;
					
					this.jpgEncoder = new JPGEncoder(this.opts.photoQuality);
					byteArray = this.jpgEncoder.encode(this.bmpData);
					
					this.debug("upload: preparing upload request header for uploading");
					var reqHeadr:URLRequestHeader = new URLRequestHeader("Accept", "text/*");
					var req:URLRequest = new URLRequest(this.opts.uploadURL);
					req.requestHeaders.push(reqHeadr);
					
					req.data = byteArray;
					req.method = URLRequestMethod.POST;
					req.contentType = "image/jpeg";
					
					this.uLoader = new URLLoader();
					
					// set the event handlers
					this.uLoader.addEventListener(Event.OPEN, this.uploadOpenHandler);
					this.uLoader.addEventListener(ProgressEvent.PROGRESS , this.uploadProgressHandler);
					this.uLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR , this.uploadSecurityErrorHandler);
					//this.uLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, this.uploadHttpStatusHandler);
					this.uLoader.addEventListener(Event.COMPLETE, this.uploadCompleteHandler);
					//this.uLoader.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, this.uploadServerDataHandler);
					this.uLoader.addEventListener(IOErrorEvent.IO_ERROR, this.uploadIOErrorHandler);
					
					this.debug("upload: sending POST to: " + this.opts.uploadURL);					
					
					if (this.opts.uploadURL.length == 0) {
						this.debug("Event: uploadError : IO Error : Upload URL string is empty.");
						ExternalCall.error(this.cbUploadError, "Upload URL string is empty.");
					} else {
						this.debug("UploadStart(): data accepted by upload event and ready for upload. Starting upload to " + req.url);
						this.uLoader.load(req);
					}
				} catch (ex:Error) {
					var msg:String = ex.errorID + "\n" + ex.name + "\n" + ex.message + "\n" + ex.getStackTrace();
					this.debug("UploadStart: Exception occurred: " + msg);
					
					this.debug("Event: UploadError: Upload Failed. Exception occurred: " + msg);
					ExternalCall.error(this.cbUploadError, msg);
					
					this.uploadComplete();
				}
			} else {
				this.debug("Event: UploadError: Nothing to upload, must capture an image first");
				ExternalCall.error(this.cbUploadError, "Nothing to upload, must capture an image first");
				
				this.debug("Event: UploadComplete: Nothing to upload.");
				this.uploadComplete();
			}
		}
		
		// stop upload
		private function stopUpload():void
		{
			if (this.trackUploading) {
				// stop the upload loader by closing it
				this.uLoader.close();
				
				this.debug("Event: uploadError: upload stopped.");
				ExternalCall.error(this.cbUploadError, "Upload Stopped.");
				
				this.uploadComplete();
				
				this.debug("StopUpload(): upload stopped.");;
			} else {
				this.debug("stopUpload(): No data is currently uploading. Nothing to do.");
			}
		}
		
		// upload complete
		private function uploadComplete():void
		{
			// remove the event handlers
			this.removeUploadEventListeners(this.uLoader);
			
			this.trackUploading = false;
			
			this.debug("Event: UploadComplete: Upload Complete.");
			ExternalCall.simple(this.cbUploadComplete);
		}
		
		// save bitmap data to image file on local disk
		private function save():void
		{
			if (this.trackSaving) {
				this.debug("save(): save already in progress. Not starting another saving.");
				return;
			}
			
			this.debug("save: ready for saving.");
			
			this.trackSaving = true;
			
			if (this.bmpData)
			{
				try {
					// Trigger the saveStart event to begin the actual save
					this.debug("event: saveStart : starting save mode");
					ExternalCall.simple(this.cbSaveStart);
					
					if ((this.opts.camWidth > this.opts.photoWidth) && (this.opts.camHeight > this.opts.photoHeight))
					{
						// resize image downward before submitting if camera dimension is greater
						this.debug("save: resize image downward before submitting if camera dimension is greater");
						var tmpData:BitmapData = new BitmapData(this.opts.photoWidth, this.opts.photoHeight);
						
						var matrix:Matrix = new Matrix();
						matrix.scale(this.opts.photoWidth / this.opts.camWidth, this.opts.photoHeight / this.opts.camHeight);
						
						tmpData.draw(this.bmpData, matrix, null, null, null, true);
						this.bmpData = tmpData;
					}
					
					this.debug("save: encoding to bitmap Data to Jpg");
					var byteArray:ByteArray;
					
					this.jpgEncoder = new JPGEncoder(this.opts.photoQuality);
					byteArray = this.jpgEncoder.encode(this.bmpData);
					
					this.debug("save: preparing file reference for saving");
					
					this.fileRef =  new FileReference();
					
					// set the event handlers
					this.fileRef.addEventListener(Event.OPEN, this.saveOpenHandler);
					this.fileRef.addEventListener(Event.SELECT, this.saveSelectHandler);
					this.fileRef.addEventListener(Event.CANCEL, this.saveCancelHandler);
					this.fileRef.addEventListener(Event.COMPLETE, this.saveCompleteHandler);
					this.fileRef.addEventListener(ProgressEvent.PROGRESS , this.saveProgressHandler);
					this.fileRef.addEventListener(IOErrorEvent.IO_ERROR, this.saveIOErrorHandler);
					
					this.debug("SaveStart(): calling save dialog box for file: " + this.opts.fileName);
					this.fileRef.save(byteArray, this.opts.fileName + ".jpg");
					
				} catch (ex:Error) {
					var msg:String = ex.errorID + "\n" + ex.name + "\n" + ex.message + "\n" + ex.getStackTrace();
					this.debug("saveStart: Exception occurred: " + msg);
					
					this.debug("Event: saveError: save Failed. Exception occurred: " + msg);
					ExternalCall.error(this.cbSaveError, msg);
					
					this.saveComplete();
				}
			} else {
				this.debug("Event: saveError: Nothing to save, must capture an image first");
				ExternalCall.error(this.cbSaveError, "Nothing to save, must capture an image first");
				
				this.debug("Event: saveComplete: Nothing to save.");
				this.saveComplete();
			}
		}
		
		// stop save
		private function stopSave():void
		{
			if (this.trackSaving) {
				// stop the file save by canceling it
				this.fileRef.cancel();
				
				this.debug("Event: saveError: file save cancelled.");
				ExternalCall.error(this.cbSaveError, "file saved cancelled.");
				
				this.saveComplete();
				
				this.debug("stopSave(): file save cancelled.");;
			} else {
				this.debug("stopSave(): No file is currently saving. Nothing to do.");
			}
		}
		
		// save complete
		private function saveComplete():void
		{
			// remove the event handlers
			this.removeSaveEventListeners(this.fileRef);
			
			this.trackSaving = false;
			
			this.debug("Event: saveComplete: save complete.");
			ExternalCall.simple(this.cbSaveComplete);
		}
		
		private function reset():void
		{
			// reset video after taking snapshot
			if (this.bmp) {
				removeChild(this.bmp);
				this.bmp = null;
				this.bmpData = null;
				
				this.video.attachCamera(this.camera);
				addChild(this.video);
				
				// disable save mode and remove save info text
				this.disableSaveMode()
			}
			
			this.debug("Reset: reset camera view.");
		}
		
		private function showSettings(sPanel:String = SecurityPanel.CAMERA):void
		{
			// show configure dialog inside flash movie
			Security.showSettings(sPanel);
			this.debug("ShowSettings: show camera setting dialog.");
		}
		
		private function testSound():void
		{
			this.debug("sound test: testing camera sound");
			this.soundChannel = this.sound.play();
		}
		
		private function testFlash():void
		{
			this.debug("flash test: testing camera flash");
			this.flashCamera();
		}
		
		private function flashCamera():void
		{
			/*
			this.debug("flash tween: Starting...");
			
			var topPosition:uint = this.numChildren - 1;
			
			this.flashCont.addChild(this.flashRect);
			this.setChildIndex(this.flashCont, topPosition);
			
			this.flashTween = new Tween(this.flashRect, "alpha", Strong.easeOut, 1, 0, 1, true);
			this.flashTween.addEventListener(TweenEvent.MOTION_FINISH, flashCameraEnd);
			*/
		}
		
		/*
		private function flashCameraEnd(event:TweenEvent):void
		{
			this.debug("flash tween: removing tween event...");
			this.flashCont.removeChild(this.flashRect);
			this.flashTween.removeEventListener(TweenEvent.MOTION_FINISH, flashCameraEnd);
			this.flashTween = null;
		}
		*/
		
		private function setInfoText(text:String):void {
			this.opts.txtInfoText = text;
			
			this.updateInfoTextStyle();
		}
		
		private function updateInfoTextStyle():void {
			var style:StyleSheet = new StyleSheet();
			style.parseCSS(this.opts.txtInfoStyle);
			this.txtInfoField.styleSheet = style;
			this.txtInfoField.htmlText = this.opts.txtInfoText;
		}
		
		private function setInfoTextStyle(textStyle:String):void {
			this.opts.txtInfoStyle = textStyle;
		}
		
		// set camera bandwidth
		private function setBandwidth(val:int = 0):void
		{
			if (val < 0) val = 0;
			if (val > 100) val = 100;
			this.opts.bandwidth = val;
			
			this.camera.setQuality(this.opts.bandwidth, this.opts.camQuality);
		}
		
		// get camera bandwidth
		private function getBandwidth():int
		{
			return this.opts.bandwidth;
		}
		
		// set camera dimension
		private function setCamDimension(w:int = 320, h:int = 240):void
		{
			this.opts.camWidth = w;
			this.opts.camHeight = h;
			
			this.stage.stageWidth = this.opts.maxWidth;
			this.stage.stageHeight = this.opts.maxHeight;
			this.setMaxDimension();
			
			updateCameraDimension();
			this.debug("camera dimension set - width: " + w + " height: " + h);
		}
		
		// get camera dimension
		private function getCamDimension():Object
		{
			return {
				width: this.opts.camWidth,
					height: this.opts.camHeight
			};
		}
		
		// set camera FPS (frames per seconds)
		private function setCamFPS(val:int = 30):void
		{
			this.opts.camFPS = val;
			this.debug("camera FPS set - FPS: " + val);
		}
		
		// get camera FPS (frames per seconds)
		private function getCamFPS():int
		{
			return this.opts.camFPS;
		}
		
		// set camera quality
		private function setCamQuality(val:int = 30):void
		{
			this.opts.camQuality = val;
			this.camera.setQuality(this.opts.bandwidth, this.opts.camQuality);
			this.debug("camera quality set - quality: " + val);
		}
		
		// get camera quality
		private function getCamQuality():int
		{
			return this.opts.camQuality;
		}
		
		// set photo dimension
		private function setPhotoDimension(w:int = 320, h:int = 240):void
		{
			this.opts.photoWidth = w;
			this.opts.photoHeight = h;
			this.debug("photo dimension set - width: " + w + " height: " + h);
		}
		
		// get photo dimension
		private function getPhotoDimension():Object
		{
			return {
				width: this.opts.photoWidth,
					height: this.opts.photoWidth
			};
		}
		
		// set photo quality
		private function setPhotoQuality(val:int = 90):void
		{
			this.opts.photoQuality = val;
			this.debug("photo quality set - quality: " + val);
		}
		
		// get photo quality
		private function getPhotoQuality():int
		{
			return this.opts.photoQuality;
		}
		
		// set sound URL
		private function setSoundURL(url:String):void
		{
			this.opts.soundURL = url;
			
			this.sound = new Sound();
			this.sound.load(new URLRequest(this.opts.soundURL));
			this.debug("sound URL set - URL: " + url);
		}
		
		// get Sound URL
		private function getSoundURL():String
		{
			return this.opts.soundURL;
		}
		
		// set upload URL
		private function setUploadURL(url:String = ""):void
		{
			this.opts.uploadURL = url;
			this.debug("upload URL set - URL: " + url);
		}
		
		// get upload URL
		private function getUploadURL():String
		{
			return this.opts.uploadURL;
		}
		
		// set file path
		private function setFileName(path:String = "image.jpg"):void
		{
			this.opts.fileName = path;
			this.debug("fileName set - path: " + path);
		}
		
		// get file path
		private function getFileName():String
		{
			return this.opts.fileName;
		}
		
		// set enable/disable sound
		private function toggleSound():Boolean
		{
			this.opts.soundEnabled = !(this.opts.soundEnabled);
			return this.opts.soundEnabled;
			this.debug("toggle camera sound - state: " + this.opts.soundEnabled.toString());
		}
		
		// set enable/disable flash
		private function toggleFlash():Boolean
		{
			this.opts.flashEnabled = !(this.opts.flashEnabled);
			return this.opts.flashEnabled;
			this.debug("toggle camera flash - state: " + this.opts.flashEnabled.toString());
		}
		
		// set enable/disable stealth
		private function toggleStealth():Boolean
		{
			this.opts.stealthEnabled = !(this.opts.stealthEnabled);
			return this.opts.stealthEnabled;
			this.debug("toggle camera stealth - state: " + this.opts.stealthEnabled.toString());
		}
		
		
		
		// show camera selectin settings
		private function selectCamera():void {
			this.showSettings(SecurityPanel.CAMERA);
			this.debug("show select camera dialog");
		}
		
		// setup callbacks
		private function setupExternalCallbacks():void
		{
			this.debug("loading sound...");
			try
			{
				ExternalInterface.addCallback("snap", this.snap);
				ExternalInterface.addCallback("upload", this.upload);
				ExternalInterface.addCallback("stopUpload", this.stopUpload);
				ExternalInterface.addCallback("save", this.save);
				ExternalInterface.addCallback("stopSave", this.stopSave);
				ExternalInterface.addCallback("reset", this.reset);
				ExternalInterface.addCallback("showSettings", this.showSettings);
				
				ExternalInterface.addCallback("setInfoText", this.setInfoText);
				ExternalInterface.addCallback("setInfoTextStyle", this.setInfoTextStyle);
				
				ExternalInterface.addCallback("setBandwidth", this.setBandwidth);
				ExternalInterface.addCallback("getBandwidth", this.getBandwidth);
				
				ExternalInterface.addCallback("setCamDimension", this.setCamDimension);
				ExternalInterface.addCallback("getCamDimension", this.getCamDimension);
				
				ExternalInterface.addCallback("setCamFPS", this.setCamFPS);
				ExternalInterface.addCallback("getCamFPS", this.getCamFPS);
				
				ExternalInterface.addCallback("setCamQuality", this.setCamQuality);
				ExternalInterface.addCallback("getCamQuality", this.getCamQuality);
				
				ExternalInterface.addCallback("setPhotoDimension", this.setPhotoDimension);
				ExternalInterface.addCallback("getPhotoDimension", this.getPhotoDimension);
				
				ExternalInterface.addCallback("setPhotoQuality", this.setPhotoQuality);
				ExternalInterface.addCallback("getPhotoQuality", this.getPhotoQuality);
				
				ExternalInterface.addCallback("setSoundURL", this.setSoundURL);
				ExternalInterface.addCallback("getSoundURL", this.getSoundURL);
				
				ExternalInterface.addCallback("setUploadURL", this.setUploadURL);
				ExternalInterface.addCallback("getUploadURL", this.getUploadURL);
				
				ExternalInterface.addCallback("setFileName", this.setFileName);
				ExternalInterface.addCallback("getFileName", this.getFileName);
				
				ExternalInterface.addCallback("toggleSound", this.toggleSound);
				ExternalInterface.addCallback("toggleFlash", this.toggleFlash);
				ExternalInterface.addCallback("toggleStealth", this.toggleStealth);
				//ExternalInterface.addCallback("toggleSettings", this.toggleSettings);
				
				ExternalInterface.addCallback("selectCamera", this.selectCamera);
				
				ExternalInterface.addCallback("testSound", this.testSound);
				ExternalInterface.addCallback("testFlash", this.testFlash);
				
				ExternalInterface.addCallback("TestExternalInterface", this.TestExternalInterface);
				
			} catch(ex:Error) {
				var msg:String = ex.errorID + "\n" + ex.name + "\n" + ex.message + "\n" + ex.getStackTrace();
				this.debug("callbacks where not set: " + msg);
				return;
			}
			
			ExternalCall.simple(this.cbCleanUp);
		}
		
		// debug
		private function debug(msg:String):void
		{
			try {
				if (this.opts.debug) {
					var lines:Array = msg.split("\n");
					for (var i:Number=0; i < lines.length; i++) {
						lines[i] = "SWF DEBUG: " + lines[i];
					}
					ExternalCall.debug(this.cbDebug, lines.join("\n"));
				}
			} catch (ex:Error) {
				// pretend nothing happened
				trace(ex);
			}
		}
		
		// print debug info
		private function printDebugInfo():void {
			var debug_info:String = "\n----- FOTOCAM DEBUG OUTPUT ----\n";
			debug_info += "version:                " + this.version + "\n";
			debug_info += "SWF ID:                 " + this.opts.swfID + "\n";
			
			debug_info += "Bandwidth:              " + this.opts.bandwidth + "\n";
			
			debug_info += "Camera Width:           " + this.opts.camWidth + "\n";
			debug_info += "Camera Height:          " + this.opts.camHeight + "\n";
			debug_info += "Camera FPS:             " + this.opts.camFPS + "\n";
			debug_info += "Camera Quality:         " + this.opts.camQuality + "\n";
			
			debug_info += "Photo Width:            " + this.opts.photoWidth + "\n";
			debug_info += "Photo Height:           " + this.opts.photoHeight + "\n";
			debug_info += "Photo Quality:          " + this.opts.photoQuality + "\n";
			
			debug_info += "Info Text:              " + this.opts.txtInfoText + "\n";
			debug_info += "Info Text Style:        " + this.opts.txtInfoStyle + "\n";
			debug_info += "Info Text Width:        " + this.opts.txtContWidth + "\n";
			debug_info += "Info Text Height:       " + this.opts.txtContHeight + "\n";
			
			//			debug_info += "SWF URL:                " + this.opts.swfURL + "\n";
			debug_info += "Sound URL:              " + this.opts.soundURL + "\n";
			debug_info += "Upload URL:             " + this.opts.uploadURL + "\n";
			debug_info += "File Path:              " + this.opts.fileName + "\n";
			
			debug_info += "Sound Enabled:          " + this.opts.soundEnabled.toString() + "\n";
			debug_info += "Flash Enabled:          " + this.opts.flashEnabled.toString() + "\n";
			debug_info += "Stealth Enabled:        " + this.opts.stealthEnabled.toString() + "\n";
			//debug_info += "Settings Enabled:       " + this.opts.settingsEnabled.toString() + "\n";
			
			debug_info += "----- END FOTOCAM DEBUG OUTPUT ----\n";
			
			this.debug(debug_info);
		}
		
		// remove upload event handlers
		private function removeUploadEventListeners(loader:URLLoader):void {
			if (this.trackUploading && loader) {
				// remove the event handlers
				loader.removeEventListener(Event.OPEN, this.uploadOpenHandler);
				loader.removeEventListener(ProgressEvent.PROGRESS , this.uploadProgressHandler);
				loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR , this.uploadSecurityErrorHandler);
				//loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, this.uploadHttpStatusHandler);
				loader.removeEventListener(Event.COMPLETE, this.uploadCompleteHandler);
				//loader.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, this.uploadServerDataHandler);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, this.uploadIOErrorHandler);
			}
		}
		
		// remove save event handlers
		private function removeSaveEventListeners(file_ref:FileReference):void {
			if (this.trackSaving && file_ref) {
				// remove the event handlers
				file_ref.removeEventListener(Event.OPEN, this.saveOpenHandler);
				file_ref.removeEventListener(Event.CANCEL, this.saveCancelHandler);
				file_ref.removeEventListener(Event.SELECT, this.saveSelectHandler);
				file_ref.removeEventListener(Event.COMPLETE, this.saveCompleteHandler);
				file_ref.removeEventListener(ProgressEvent.PROGRESS , this.saveProgressHandler);
				file_ref.removeEventListener(IOErrorEvent.IO_ERROR, this.saveIOErrorHandler);
			}
		}
	}
}