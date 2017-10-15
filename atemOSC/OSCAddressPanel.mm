//
//  OSCAddressPanel.m
//  AtemOSC
//
//  Created by Peter Steffey on 10/10/17.
//

#import "OSCAddressPanel.h"
#import "AppDelegate.h"

@implementation OSCAddressPanel

- (void)setupWithDelegate:(AppDelegate *)appDel
{
    //set helptext
    [helpTextView setAlignment:NSLeftTextAlignment];
    
    NSMutableAttributedString * helpString = [[NSMutableAttributedString alloc] initWithString:@""];
    NSDictionary *infoAttribute = @{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Monaco" traits:NSUnboldFontMask|NSUnitalicFontMask weight:5 size:12]};
    NSDictionary *addressAttribute = @{NSFontAttributeName: [[NSFontManager sharedFontManager] fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:5 size:12]};
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"Transitions:\n" attributes:addressAttribute]];
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tT-Bar: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/bar\n" attributes:infoAttribute]];
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tCut: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/cut\n" attributes:infoAttribute]];
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tAuto-Cut: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/auto\n" attributes:infoAttribute]];
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tFade-to-black: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/ftb\n" attributes:infoAttribute]];
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nTransition type:\n" attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet to Mix: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/set-type/mix\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet to Dip: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/set-type/dip\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet to Wipe: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/set-type/wipe\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet to Stinger: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/set-type/sting\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet to DVE: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/transition/set-type/dve\n" attributes:infoAttribute]];
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nUpstream Keyers:\n" attributes:addressAttribute]];
    for (int i = 0; i<[appDel keyers].size();i++)
    {
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tOn Air KEY %d toggle: ",i+1] attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/usk/%d\n",i+1] attributes:infoAttribute]];
    }
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tBKGD: "] attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/nextusk/0\n"] attributes:infoAttribute]];
    for (int i = 0; i<[appDel keyers].size();i++)
    {
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tKEY %d: ",i+1] attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/nextusk/%d\n",i+1] attributes:infoAttribute]];
    }
    
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nDownstream Keyers:\n" attributes:addressAttribute]];
    for (int i = 0; i<[appDel dsk].size();i++)
    {
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tAuto-Transistion DSK%d: ",i+1] attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/dsk/%d\n",i+1] attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet DSK On Ait%d: ",i+1] attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/dsk/on-air/%d\t<0|1>\n",i+1] attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tTie Next-Transistion DSK%d: ",i+1] attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/dsk/tie/%d\n",i+1] attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Tie Next-Transistion DSK%d: ",i+1] attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/dsk/set-tie/%d\t<0|1>\n",i+1] attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tToggle DSK%d: ",i+1] attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/dsk/toggle/%d\n",i+1] attributes:infoAttribute]];
    }
    
    
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nSources:\n" attributes:addressAttribute]];
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nAux Outputs:\n" attributes:addressAttribute]];
    for (int i = 0; i<[appDel mSwitcherInputAuxList].size();i++)
    {
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Aux %d to Source: ",i+1] attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/aux/%d\t<valid_program_source>\n",i+1] attributes:infoAttribute]];
    }
    
    if ([appDel mMediaPlayers].size() > 0)
    {
        uint32_t clipCount;
        uint32_t stillCount;
        HRESULT result;
        result = [appDel mMediaPool]->GetClipCount(&clipCount);
        if (FAILED(result))
        {
            // the default number of clips
            clipCount = 2;
        }
        
        IBMDSwitcherStills* mStills = [appDel mStills];
        result = [appDel mMediaPool]->GetStills(&mStills);
        if (FAILED(result))
        {
            // ATEM TVS only supports 20 stills, the others are 32
            stillCount = 20;
        }
        else
        {
            result = [appDel mStills]->GetCount(&stillCount);
            if (FAILED(result))
            {
                // ATEM TVS only supports 20 stills, the others are 32
                stillCount = 20;
            }
        }
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nMedia Players:\n" attributes:addressAttribute]];
        for (int i = 0; i < [appDel mMediaPlayers].size(); i++)
        {
            for (int j = 0; j < clipCount; j++)
            {
                [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet MP %d to Clip %d: ",i+1,j+1] attributes:  addressAttribute]];
                [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/mplayer/%d/clip/%d\n",i+1,j+1] attributes:infoAttribute]];
            }
            for (int j = 0; j < stillCount; j++)
            {
                [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet MP %d to Still %d: ",i+1,j+1] attributes:  addressAttribute]];
                [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/mplayer/%d/still/%d\n",i+1,j+1] attributes:infoAttribute]];
            }
        }
    }
    
    
    if ([appDel mSuperSourceBoxes].size() > 0)
    {
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nSuper Source:\n" attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tValid values specified in <>\n\n" attributes:addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet the border enabled flag: " attributes:  addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/supersource/border-enabled\t<0|1>\n" attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet the border outer width: " attributes:  addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/supersource/border-outer\t<float>\n" attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet the border inner width: " attributes:  addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/supersource/border-inner\t<float>\n" attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet the border hue: " attributes:  addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/supersource/border-hue\t<float>\n" attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet the border saturation: " attributes:  addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/supersource/border-saturation\t<float>\n" attributes:infoAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tSet the border luminescence: " attributes:  addressAttribute]];
        [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/supersource/border-luminescence\t<float>\n" attributes:infoAttribute]];
        for (int i = 1; i <= [appDel mSuperSourceBoxes].size(); i++)
        {
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d enabled: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/enabled\t<0|1>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Input source: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/source\t<see sources for valid options>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Position X: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/x\t<float>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Position Y: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/y\t<float>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Size: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/size\t<float>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Cropped Enabled: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/cropped\t<0|1>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Crop Top: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-top\t<float>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Crop Bottom: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-bottom\t<float>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Crop Left: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-left\t<float>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tSet Box %d Crop Right: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-right\t<float>\n",i] attributes:infoAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\tReset Box %d Crop: ",i] attributes:  addressAttribute]];
            [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"/atem/supersource/box/%d/crop-reset\t<1>\n",i] attributes:infoAttribute]];
        }
    }
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\nMacros:\n" attributes:addressAttribute]];
    
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tGet the Maximum Number of Macros: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/macros/get-max-number\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tStop the currently active Macro (if any): " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/macros/stop\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tGet the Name of a Macro: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/macros/<index>/name\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tGet the Description of a Macro: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/macros/<index>/description\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tGet whether the Macro at <index> is valid: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/macros/<index>/is-valid\n" attributes:infoAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\tRun the Macro at <index>: " attributes:addressAttribute]];
    [helpString appendAttributedString:[[NSAttributedString alloc] initWithString:@"/atem/macros/<index>/run\n" attributes:infoAttribute]];
    
    [helpString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0,helpString.length)];
    [[helpTextView textStorage] setAttributedString:helpString];
}

@end
