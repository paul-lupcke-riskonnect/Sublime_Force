/*
 * MultiselectController synchronizes the values of the hidden elements to the
 * SelectOption lists.
 */
public with sharing class MultiselectController {
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
    public List<SelectOption[]> rightSelection { 
        get; 
        set{
            //System.debug('Setting rightSelection'+value+':');
            rightSelection=value;
        }
    }
    public List<SelectOption[]> leftSelection { 
        get; 
        set{
            //System.debug('Setting leftSelection:'+value+':');
            leftSelection=value;
            if(leftSelection.size()>0){
                leftOptions=leftSelection[0];
                //System.debug('Setting left option to:'+leftOptions);
                //System.debug('For giggles:'+rightOptions);
                //System.debug('For giggles2:'+rightSelection);
                
                leftOptions = cleaned(leftSelection[0],rightOptions);
            }
        }
    }

    private SelectOption[] cleaned (SelectOption[] all, SelectOption[] sel){
        SelectOption[] retVal = new SelectOption[]{};
        Boolean addFlag;
        for(Integer i=0;i<all.size();++i){
            addFlag=true;
            System.debug('All:'+all+':: Size:'+all.size()+';');
            System.debug('Sel:'+sel+':: Size:'+sel.size()+';');
            for(Integer j=0;j<sel.size();++j){
                System.debug('I:'+i+':: J:'+j);
                if(all[i].getValue()==sel[j].getValue()){
                    System.debug('Removing I:'+i);
                    addFlag=false;
                    //all.remove(i);
                    //--i;
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
                indexID='0.0';
            }
        }
    }
    
    public MultiselectController(){
        //System.debug('MultiselectController Constructor called.');
        leftSelection = new List<SelectOption[]>();
        rightSelection = new List<SelectOption[]>();
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
    private void setOptions(List<SelectOption[]> options, String value) {
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
           setOptions(rightSelection, value);
        }
    }
}