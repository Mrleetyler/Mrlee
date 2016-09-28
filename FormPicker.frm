VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} FormPicker 
   Caption         =   "Choose a date"
   ClientHeight    =   2415
   ClientLeft      =   45
   ClientTop       =   375
   ClientWidth     =   1965
   OleObjectBlob   =   "FormPicker.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "FormPicker"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Option Explicit

'**********  CODE FOR CUSTOM DATE PICKER  ***********
'I used to use the MouseDown event, but I found that it wasn't responsive to double-clicks, so now I
'use a combination of the MouseMove event to get the coordinates, and both the Click and DblClick events.
Private Sub LabelClickArea_Click()
    clsCal.CaptureClick
End Sub
Private Sub LabelClickArea_DblClick(ByVal Cancel As MSForms.ReturnBoolean)
    clsCal.CaptureClick
    Cancel = True
End Sub
Private Sub LabelClickArea_MouseMove(ByVal Button As Integer, ByVal Shift As Integer, ByVal X As Single, ByVal Y As Single)
    With clsCal
        .sngX = X
        .sngY = Y
    End With
End Sub
'***************  END CODE  ****************

Private Sub UserForm_Initialize()
    Set clsCal.BoundForm = Me
    clsCal.LoadView
End Sub
