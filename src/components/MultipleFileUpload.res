external toReactEvent: 'a => ReactEvent.Form.t = "%identity"
external arrToReactEvent: array<string> => ReactEvent.Form.t = "%identity"
external strToReactEvent: string => ReactEvent.Form.t = "%identity"
type dataTransfer
@get external dataTransfer: ReactEvent.Mouse.t => 'a = "dataTransfer"
@get external files: dataTransfer => 'a = "files"
open LogicUtils

@val external atob: string => string = "atob"
@send external focus: Dom.element => unit = "focus"
@react.component
let make = (
  ~input: ReactFinalForm.fieldRenderPropsInput,
  ~fileType=".pdf",
  ~fileNamesInput: option<ReactFinalForm.fieldRenderPropsInput>=?,
  ~isDisabled=false,
  ~shouldParse=true,
  ~showUploadtoast=true,
  ~parseFile=str => str,
  ~shouldEncodeBase64=false,
  ~decodeParsedfile=false,
  ~widthClass="w-[253px]",
  ~heightClass="h-[74px]",
  ~buttonHeightClass="",
  ~parentDisplayClass="flex gap-5",
  ~displayClass="flex flex-col flex-wrap overflow-auto",
  ~buttonElement=?,
  ~rowsLimit=?,
  ~validateUploadedFile=?,
  ~allowMultiFileSelect=false,
  ~fileOnClick=(_, _) => (),
  ~customDownload=false,
  ~sizeLimit=?,
  ~pointerDisable=false,
) => {
  let (key, setKey) = React.useState(_ => 1)
  let fileNamesInput = switch fileNamesInput {
  | Some(filenamesInput) => filenamesInput
  | None => ReactFinalForm.useField(input.name ++ "_filenames").input
  }
  let fileTypeInput = ReactFinalForm.useField(input.name ++ "_filemimes").input

  let defaultFileNames = fileNamesInput.value->getStrArryFromJson
  // let defaultFileMimes = input.value->getArrayFromJson([])

  let (fileNames, setFilenames) = React.useState(_ => defaultFileNames)
  let (fileTypes, setFileTypes) = React.useState(_ => defaultFileNames)
  let showToast = ToastState.useShowToast()

  React.useEffect2(() => {
    fileNamesInput.onChange(fileNames->toReactEvent)
    fileTypeInput.onChange(fileTypes->toReactEvent)
    None
  }, (fileNames, fileTypes))

  let clearData = indx => {
    setFilenames(prev => prev->Js.Array2.filteri((_, i) => indx !== i))
    setFileTypes(prev => prev->Js.Array2.filteri((_, i) => indx !== i))
    input.onChange(
      input.value
      ->getArrayFromJson([])
      ->Js.Array2.filteri((_, i) => indx != i)
      ->Js.Json.array
      ->toReactEvent,
    )
    setKey(prev => prev + 1)
  }

  let toast = (message, toastType) => {
    showToast(~message, ~toastType, ())
  }

  let fileEmptyCheckUpload = (~value, ~files, ~filename, ~mimeType) => {
    if value !== "" {
      setFilenames(prev => {
        let fileArr = prev->Js.Array2.copy->Js.Array2.concat(filename)
        fileArr
      })
      setFileTypes(prev => {
        let mimeArr = prev->Js.Array2.copy->Js.Array2.concat(mimeType)
        mimeArr
      })

      files->Js.Array2.push(value->Js.Json.string)->ignore
      if showUploadtoast {
        toast("File Uploaded Successfully", ToastSuccess)
      }
    } else {
      toast("Error uploading file", ToastError)
    }
  }

  let onChange = evt => {
    let target = ReactEvent.Form.target(evt)
    let arr = [0]
    let break = ref(false)
    let files = input.value->LogicUtils.getArrayFromJson([])

    while !break.contents {
      if target["files"]->Js.Array2.length > arr[0]->Belt.Option.getWithDefault(0) {
        let index = arr->Belt.Array.get(0)->Belt.Option.getWithDefault(0)
        switch target["files"][index] {
        | Some(value) => {
            let filename = value["name"]
            let size = value["size"]
            let mimeType = value["type"]
            let fileFormat = Js.String2.concat(
              ".",
              Js.Array2.pop(filename->Js.String2.split("."))->Belt.Option.getWithDefault(""),
            )
            let fileTypeArr = fileType->Js.String2.split(",")
            let isCorrectFileFormat =
              fileTypeArr->Js.Array2.includes(fileFormat) || fileTypeArr->Js.Array2.includes("*")
            let fileReader = FileReader.reader
            let _file = if filename->Js.String2.includes("p12") {
              fileReader.readAsBinaryString(. value)
            } else if shouldEncodeBase64 {
              fileReader.readAsDataURL(. value)
            } else {
              fileReader.readAsText(. value)
            }

            fileReader.onload = e => {
              let target = ReactEvent.Form.target(e)
              let file = target["result"]
              let value = shouldParse ? file->parseFile : value
              let isValid = switch validateUploadedFile {
              | Some(fn) => fn(file)
              | _ => true
              }

              if !isCorrectFileFormat {
                input.onChange(toReactEvent(""))
                toast("Invalid file format", ToastError)
              } else if isValid {
                switch sizeLimit {
                | Some(sizeLimit) =>
                  if size > sizeLimit {
                    showToast(
                      ~message=`File size too large, upload below ${(sizeLimit / 1000)
                          ->Belt.Int.toString}kb`,
                      ~toastType=ToastError,
                      (),
                    )
                  } else {
                    switch rowsLimit {
                    | Some(val) =>
                      let rows = Js.String2.split(file, "\n")->Js.Array2.length
                      if value !== "" && rows - 1 < val {
                        setFilenames(prev => {
                          let fileArr = prev->Js.Array2.copy->Js.Array2.concat(filename)
                          fileArr
                        })
                        setFileTypes(prev => {
                          let mimeArr = prev->Js.Array2.copy->Js.Array2.concat(mimeType)
                          mimeArr
                        })

                        files->Js.Array2.push(value->Js.Json.string)->ignore

                        if showUploadtoast {
                          toast("File Uploaded Successfully", ToastSuccess)
                        }
                      } else if showUploadtoast {
                        toast("File Size Exceeded", ToastError)
                      }
                    | None => fileEmptyCheckUpload(~value, ~files, ~filename, ~mimeType)
                    }
                  }
                | None => fileEmptyCheckUpload(~value, ~files, ~filename, ~mimeType)
                }
              } else {
                toast("Invalid file", ToastError)
              }
            }
            arr->Belt.Array.set(0, arr[0]->Belt.Option.getWithDefault(0) + 1)->ignore
          }
        | None => ()
        }
      } else {
        break := true
      }
      input.onChange(toReactEvent(files))
    }
  }

  let val = getArrayFromJson(input.value, [])

  let onClick = (fileName, indx) => {
    DownloadUtils.downloadOld(
      ~fileName,
      ~content=decodeParsedfile
        ? try {
            val
            ->Belt.Array.get(indx)
            ->Belt.Option.getWithDefault(Js.Json.null)
            ->getStringFromJson("")
            ->atob
          } catch {
          | _ =>
            toast("Error : Unable to parse file", ToastError)
            ""
          }
        : val
          ->Belt.Array.get(indx)
          ->Belt.Option.getWithDefault(Js.Json.null)
          ->getStringFromJson(""),
    )
  }

  let cursor = isDisabled ? "cursor-not-allowed" : "cursor-pointer"

  <div className={`${parentDisplayClass}`}>
    <label>
      <div
        onDragOver={ev => {
          ev->ReactEvent.Mouse.preventDefault
        }}
        onDrop={ev => {
          ReactEvent.Mouse.preventDefault(ev)
          let files = ev->dataTransfer->files
          if files->Js.Array2.length > 0 {
            let file = files["0"]
            let filename = file["name"]
            let mimeType = file["type"]
            setFilenames(prev => prev->Js.Array2.concat(filename))
            setFileTypes(prev => prev->Js.Array2.concat(mimeType))
            input.onChange(
              toReactEvent(
                input.value->getArrayFromJson([])->Js.Array2.concat([file->Js.Json.string]),
              ),
            )
          }
        }}>
        {if !isDisabled {
          <input
            key={string_of_int(key)}
            type_="file"
            accept={fileType}
            hidden=true
            onChange
            multiple=allowMultiFileSelect
          />
        } else {
          React.null
        }}
        {switch buttonElement {
        | Some(element) => element
        | None =>
          <div
            className={`flex items-center justify-center gap-2 ${cursor} ${widthClass} ${heightClass} ${buttonHeightClass} rounded-md border border-[#8C8E9D4D] text-[#0E111E] `}>
            <Icon name="cloud-upload-alt" />
            <span> {"Upload files"->React.string} </span>
          </div>
        }}
      </div>
    </label>
    <div className={`${heightClass} ${displayClass} justify-between gap-x-5`}>
      {fileNames
      ->Js.Array2.mapi((fileName, indx) => {
        <div
          key={indx->Belt.Int.toString} className="flex items-center border p-2 gap-4 rounded-lg">
          <div
            className={pointerDisable
              ? "flex items-center gap-4 flex-1 pointer-events-none"
              : "flex items-center gap-4 flex-1"}>
            {switch fileName->Js.String2.split(".")->Js.Array2.pop->Belt.Option.getWithDefault("") {
            | "pdf" => <img src={`/icons/paIcons/pdfIcon.svg`} />
            | "csv" => <img src={`/icons/paIcons/csvIcon.svg`} />
            | _ => React.null
            }}
            <div
              className="flex flex-row text-sm text-jp-gray-900 dark:text-jp-gray-text_darktheme dark:text-opacity-40 text-opacity-50 font-medium"
              onClick={_ =>
                if customDownload {
                  fileOnClick(indx, fileName)
                } else {
                  onClick(fileName, indx)
                }}>
              {React.string(fileName)}
            </div>
          </div>
          {if !isDisabled {
            <Icon
              onClick={_ => clearData(indx)}
              className="cursor-pointer text-jp-gray-900 text-opacity-50"
              size=14
              name="times"
            />
          } else {
            React.null
          }}
        </div>
      })
      ->React.array}
    </div>
  </div>
}
