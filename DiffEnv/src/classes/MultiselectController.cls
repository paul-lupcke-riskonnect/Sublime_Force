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
    public List<SelectOption[]> rightOptions { get; set;}
    public String indexID { get; set{System.debug('Setting value for Index ID:'+value+': right option ='+rightOptions+';'); indexID=value; }}
    
    public MultiselectController(){
        System.debug('MultiselectController Constructor called.');
        leftOptions = new SelectOption[]{};
        rightOptions = new List<SelectOption[]>();
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
           setOptions(this.rightOptions, value);
        }
    }
}