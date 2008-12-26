package com.j2as3 {
    import flash.desktop.ClipboardFormats;
    import flash.events.Event;
    import flash.events.NativeDragEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.controls.ProgressBar;
    import mx.controls.TextArea;
    import mx.controls.TextInput;
    import mx.core.WindowedApplication;
    import mx.formatters.NumberFormatter;
    import mx.managers.DragManager;

    public class J2AS3Application extends WindowedApplication {
        public var textArea:TextArea;
        public var outputButton:Button;
        public var inputButton:Button;
        public var progressBar:ProgressBar;
        [Bindable] protected var inputDirSelected:Boolean = false;
        [Bindable] protected var outputDirSelected:Boolean = false;
        [Bindable] protected var _outputDir:String;
        [Bindable] protected var _inputDir:String;
        protected var outputFile:File;
        protected var inputFile:File;
        protected var fileCount:int;
        protected var javaFileCount:int;
        protected var dirCount:int;
        protected var classCount:int;
        protected var lineCount:int;
        protected var numberFormatter:NumberFormatter = new NumberFormatter();
        
        public function J2AS3Application() {
            super();
        }
        
        override protected function createChildren():void{
            super.createChildren();
            outputButton.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onOutputDragEnter, false, 0.0, true);
            outputButton.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,  onOutputDragDrop,  false, 0.0, true);
            inputButton .addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onInputDragEnter,  false, 0.0, true);
            inputButton .addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,  onInputDragDrop,   false, 0.0, true);
        }
        
        private function convertFile(file:File):void {
            var code:String;
            var fileStream:FileStream = new FileStream();
            fileStream.open(file, FileMode.READ);
            try {
                code = fileStream.readUTFBytes(fileStream.bytesAvailable);                
            } finally {
                fileStream.close();
            }
            while (code.search("\r")>-1)
                code = code.replace("\r", "");
            var converter:Converter = new Converter(code);
            var as3Code:String = converter.getNewClass();
            if (converter.isJavaFile) {
                javaFileCount++;
                classCount += converter.classCount;
                lineCount += converter.lineCount;
            }
            writeFile(file, as3Code); 
        }
        
        protected function doConvert():void {
        	lineCount = dirCount = fileCount = javaFileCount = 0;
        	progressBar.visible = true;
            textArea.text = "";
            var arr:Array = inputFile.getDirectoryListing();
            var ind:Number = 0;
            progressBar.minimum = 0;
            progressBar.maximum = arr.length;
            for each (var file:File in arr) {
                progressBar.setProgress(ind++, arr.length);
                if (file.isDirectory) {  // TODO recurse
                    dirCount++;
                    continue;
                }
                convertFile(file);                   
                textArea.text += file.name + "\n";
                fileCount++;
            }
            progressBar.setProgress(arr.length, arr.length);
            textArea.text += "===============================\n";
            textArea.text += numberFormatter.format(fileCount) + " total files\n";
            textArea.text += numberFormatter.format(javaFileCount) + " Java files\n";
            textArea.text += numberFormatter.format(classCount) + " Java classes\n";       
            textArea.text += numberFormatter.format(lineCount) + " total lines of Java code\n";       
        }
        
        protected function doInput():void {
            var file:File = new File(_inputDir);
            file.addEventListener(Event.SELECT, onInputDirSelect, false, 0.0, true);
            file.browseForDirectory("Select Java directory to read from");         
        }
        
        protected function doOutput():void {
            var file:File = new File(_outputDir);
            file.addEventListener(Event.SELECT, onOutputDirSelect, false, 0.0, true);
            file.browseForDirectory("Select AS3 directory to write to");
        }
        
        /** Set _inputDir and inputFile if the associated TextInput (inputDir) names a valid directory */
        protected function onInputChange(event:Event):void {
        	var inputDir:TextInput = TextInput(event.currentTarget);
        	var dirName:String = inputDir.text;
        	var file:File = validDirectory(dirName);
        	if (file) {
        	    setInput(file);
        		inputDir.selectionBeginIndex = inputDir.textWidth-1;
        		inputDir.selectionEndIndex = inputDir.textWidth-1;
        	} else
                inputDirSelected = false;
        }

        private function onInputDirSelect(event:Event):void {
            inputFile = event.target as File;
            setInput(inputFile);
        }
        
        private function onInputDragDrop(event:NativeDragEvent):void {
            if (event.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)) {
                var files:Array = event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
                if (files) {
		            inputFile = files[0];
		            _inputDir = inputFile.nativePath;
		            inputDirSelected = true;
                }
            }            
        } 
        
        private function onInputDragEnter(event:NativeDragEvent):void {
            if (event.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
                DragManager.acceptDragDrop(inputButton);                
        }
        
        protected function onInputFocusOut(event:Event):void {
        	var inputDir:TextInput = TextInput(event.currentTarget);
        	var dirName:String = inputDir.text;
        	if (dirName.length==0)
        		return;
        		
        	var file:File = validDirectory(dirName);
        	if (file) {
        		setInput(file);
        	} else {
        		Alert.show(dirName + " is not a directory, please respecify");
        		inputDir.selectionBeginIndex = inputDir.textWidth-1;
        		inputDir.selectionEndIndex   = inputDir.textWidth-1;
        	}
        }
        
        /** Set _outputDir and outputFile if the associated TextInput (outputDir) names a valid directory */
        protected function onOutputChange(event:Event):void {
        	var outputDir:TextInput = TextInput(event.currentTarget);
        	var dirName:String = outputDir.text;
        	var file:File = validDirectory(dirName);
        	if (file) {
        		setOutput(file);
        		outputDir.selectionBeginIndex = outputDir.textWidth-1;
        		outputDir.selectionEndIndex = outputDir.textWidth-1;
        	} else
                outputDirSelected = false;
        }
        
        private function onOutputDragDrop(event:NativeDragEvent):void {
            if (event.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)) {
                var files:Array = event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
                if (files) {
                    outputDirSelected = true;
                    outputFile = files[0];
                    _outputDir = outputFile.nativePath;
                } 
            }            
        } 
               
        private function onOutputDragEnter(event:NativeDragEvent):void {
            if (event.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
                DragManager.acceptDragDrop(outputButton);                
        }

        private function onOutputDirSelect(event:Event):void {
            outputFile = event.target as File;
            setOutput(outputFile);
        }
        
        protected function onOutputFocusOut(event:Event):void {
        	var outputDir:TextInput = TextInput(event.currentTarget);
        	var dirName:String = outputDir.text;
        	if (dirName.length==0)
        		return;
        		
        	var file:File = validDirectory(dirName);
        	if (file) {
        		setOutput(file);
        	} else {
        		Alert.show(dirName + " is not a directory, please respecify");
        		outputDir.selectionBeginIndex = outputDir.textWidth-1;
        		outputDir.selectionEndIndex   = outputDir.textWidth-1;
        	}
        }
        
		private function setInput(file:File):void {
    		inputFile = file;
    	    _inputDir = file.nativePath;
            inputDirSelected = true;
    	}

		private function setOutput(file:File):void {
    		outputFile = file;
    	    _outputDir = file.nativePath;
            outputDirSelected = true;
    	}
        
        private function validDirectory(dirName:String):File {
        	try {
	        	var file:File = new File(dirName);
	        	if (file.exists) 
					return file;
        	} catch (ignored:Error) {}
        	return null;
		}
        
        private function writeFile(orig:File, as3Code:String):void {
            var dest:File = outputFile.resolvePath(orig.name.replace(".java", ".as"));
            var fileStream : FileStream = new FileStream();
            fileStream.open(dest, FileMode.WRITE);
            try {
                fileStream.writeUTFBytes(as3Code);                
            } finally {
                fileStream.close();
            }         
        }
    }
}