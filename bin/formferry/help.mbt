///|
fn usage() -> String {
  (
    #|FormFerry commands:
    #|  fields|values|schema|check INPUT.pdf
    #|  validate|validate-complete INPUT.pdf VALUES.json [--fit-text]
    #|  fill|complete INPUT.pdf VALUES.json NEW.pdf [--fit-text]
    #|  batch|batch-complete INPUT.pdf RECORDS.json NEW_DIRECTORY [--fit-text]
    #|  batch-csv|batch-csv-complete INPUT.pdf RECORDS.csv NEW_DIRECTORY [--fit-text]
    #|  reset INPUT.pdf NAMES.json NEW.pdf [--fit-text]
    #|  lock|lock-complete INPUT.pdf NAMES.json NEW.pdf
    #|  export-fdf INPUT.pdf NEW.fdf
    #|  fill-fdf INPUT.pdf VALUES.fdf NEW.pdf [--fit-text]
    #|Existing output paths are refused. See docs/ for exact format profiles.
  )
}
