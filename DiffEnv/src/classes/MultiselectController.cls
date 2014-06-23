/*
 * MultiselectController synchronizes the values of the hidden elements to the
 * SelectOption lists.
 */
public with sharing class MultiselectController {  //(PAL) 100% coverage
    // SelectOption lists for public consumption
    public SelectOption[] leftOptions { get; 
        set{SelectOption[] tmp = value;
        if(tmp==null){tmp=new SelectOption[]{};}
        this.leftOptions=tmp;
        }
    }
    public SelectOption[] rightOptions { get; 
        set{SelectOption[] tmp = value;
        if(tmp==null){tmp=new SelectOption[]{};}
        this.rightOptions=tmp;
        }
    }
    public List<Integer> removeOptions{
        get;
        set{
            removeOptions=value;
            //System.debug('component remove option:'+value);
        }
    }
    public List<SelectOption[]> returnValue{        //(PAL) Used to return the values from the components on the page.
        get;
        set;
    }
    public List<SelectOption[]> rightSelection {    //(PAL) Used to set the right side of the select box.
        get; 
        set{
            //System.debug('setting right side:'+value+':::size:'+value.size()+':::index:'+indexID);
            rightSelection=value;

            if(rightSelection.size()>0 && rightSelection.size()>Integer.valueOf(indexID)){
                rightOptions=rightSelection[Integer.valueOf(indexID)];
                //System.debug('actually setting RightOption='+rightOptions+';');
            }
        }
    }
    public List<SelectOption[]> leftSelection { //(PAL) Used to set the left side of the select box.
        get; 
        set{
            //System.debug('setting left side:'+value+':::size:'+value.size()+':::index:'+indexID);

            leftSelection=value;
            
            if(leftSelection.size()>0 ){
                leftOptions=leftSelection[0];
                leftOptions = cleaned(leftSelection[0],rightOptions);
            }
        }
    }

    private SelectOption[] cleaned (SelectOption[] all, SelectOption[] sel){    //(PAL) Used to remove options from the left box since they are in the right box
        SelectOption[] retVal = new SelectOption[]{};
        Boolean addFlag;
        for(Integer i=0;i<all.size();++i){
            addFlag=true;
            for(Integer j=0;j<sel.size();++j){
                if(all[i].getValue()==sel[j].getValue()){
                    addFlag=false;
                }
            }
            if(addFlag==true){
                retVal.add(all[i]);
            }
        }
        return retVal;
    }

    public String indexID {
        get;
        set{
            //System.debug('Setting value for Index ID:'+value+':');
            if(value!=null){
                indexID=value;
            }
            else{
                indexID='0';
            }
        }
    }
    
    public MultiselectController(){
        //System.debug('MultiselectController Constructor called.');
        leftSelection = new List<SelectOption[]>();
        rightSelection = new List<SelectOption[]>();
        removeOptions = new List<Integer>();
        returnValue = new List<SelectOption[]>();

        leftOptions = new SelectOption[]{};
        rightOptions = new SelectOption[]{};
        indexID = '';
        //rightOptions[0] = '';
    }

    // Parse &-separated values and labels from value and 
    // put them in option
    private void setOptions(SelectOption[] options, String value) {
        options.clear();
        String[] parts = value.split('&');
        for (Integer i=0; i<parts.size()/2; i++) {
            options.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
              EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        }
    }
    private void setOptions(List<SelectOption[]> options, String value) {   //(PAL) Used to load the List of SelectOption arrays for return values
        //options.clear();
        options.add(new SelectOption[]{});
        String[] parts = value.split('&');
        for (Integer i=0; i<parts.size()/2; i++) {
            options[(options.size()-1)].add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
              EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        }
    }
    
    // Backing for hidden text field containing the options from the
    // left list
    public String leftOptionsHidden { get; set {
           leftOptionsHidden = value;
           setOptions(leftOptions, value);
        }
    }
    
    // Backing for hidden text field containing the options from the
    // right list
    public String rightOptionsHidden { get; set {
           rightOptionsHidden = value;
           setOptions(rightOptions, value);
           setOptions(returnValue, value);
        }
    }
}