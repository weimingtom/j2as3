package com.j2as3 {
    import flash.desktop.ClipboardFormats;
    import flash.events.Event;
    import flash.events.NativeDragEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    
    import mx.controls.Alert;
    import mx.controls.Button;
    import mx.controls.CheckBox;
    import mx.controls.ProgressBar;
    import mx.controls.TextArea;
    import mx.controls.TextInput;
    import mx.core.WindowedApplication;
    import mx.formatters.NumberFormatter;
    import mx.managers.DragManager;

	/** @author Mike Slinn <mslinn@mslinn.com>
	 * TODO make progress bar work; need to scan through input directory first, counting files. 
	 * This is a screwy way to organize code, but because it works I'm not going to mess with it */
    public class J2AS3Application extends WindowedApplication {
        public var textArea:TextArea;
        public var outputButton:Button;
        public var inputButton:Button;
        public var progressBar:ProgressBar;
        public var copyAssets:CheckBox;
        
        [Bindable] protected var inputDirSelected:Boolean = false;
        [Bindable] protected var outputDirSelected:Boolean = false;
        [Bindable] protected var _outputDir:String;
        [Bindable] protected var _inputDir:String;
        
        private static var numberFormatter:NumberFormatter = new NumberFormatter();

        private var outputFile:File;
        private var inputFile:File;
        private var fileCount:int;
        private var javaFileCount:int;
        private var dirCount:int;
        private var classCount:int;
        private var lineCount:int;
        
        
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
        
        private function convertDirectory(inputFile:File, outputFile:File):void {
            var files:Array = inputFile.getDirectoryListing();
            var ind:Number = 0;
            for each (var anInputFile:File in files) {
                progressBar.setProgress(ind++, files.length);
            	if (anInputFile.isHidden)
            		continue;
                var outputFile2:File = new File(outputFile.nativePath + File.separator + anInputFile.name);
                if (anInputFile.isDirectory) {
                	if (anInputFile.name=="CVS")
                		continue;
                    dirCount++;
                    convertDirectory(anInputFile, outputFile2);
                } else {
                	//File.mkdir(outputFile2.parent); is this necessary?  how to do it if so?
                	if (anInputFile.name.match(".*\\.java"))
	                	convertFile(anInputFile, outputFile);
					else if (copyAssets.selected)
						anInputFile.copyTo(outputFile2, true);	                           
	                textArea.text += anInputFile.name + "\n";
	                fileCount++;
                }
            }
        }
        
        private function convertFile(anInputFile:File, outputFile:File):void {
            var code:String;
            var fileStream:FileStream = new FileStream();
            fileStream.open(anInputFile, FileMode.READ);
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
            writeFile(anInputFile, outputFile, as3Code); 
        }
        
        protected function doConvert():void {
        	classCount = lineCount = dirCount = fileCount = javaFileCount = 0;
        	progressBar.visible = true;
            textArea.text = "";
            progressBar.minimum = 0;
            progressBar.maximum = 100;
            convertDirectory(inputFile, outputFile);
            progressBar.setProgress(100, 100);
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
        
        private function writeFile(anInputFile:File, outputFile:File, as3Code:String):void {
            var destFile:File = outputFile.resolvePath(anInputFile.name.replace(".java", ".as"));
            var fileStream:FileStream = new FileStream();
            fileStream.open(destFile, FileMode.WRITE);
            try {
                fileStream.writeUTFBytes(as3Code);                
            } finally {
                fileStream.close();
            }         
        }
    }
}