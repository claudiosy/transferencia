Imports Microsoft.VisualBasic
Imports System.Data.SqlClient
Imports System.Configuration
Imports System.Data
Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Drawing.Imaging
Imports System.Text
Imports System.IO
Imports System.Security.Cryptography
Imports System.Collections.Generic
Imports System.Linq
Imports System.Net.Mail
Imports AjaxControlToolkit
Imports Gsurf_Principal
Imports Gsurf_Homolog
Imports Newtonsoft.Json.Linq

Public Class ExecutaSP
    Public Transacao As SqlTransaction
    Public Conexao As SqlConnection
    Public Comando(0) As SqlCommand
    Public Debug As String
    Public NomeSP As String
    Public Comando_Log As SqlCommand

    Public Sub New(ByVal SP As String)
        Conexao = Conexao_AC()

        Comando(0) = New SqlCommand(SP, Conexao)
        Comando_Log = New SqlCommand("AC_SP_INS_LOG", Conexao)
        Conexao.Open()

        Transacao = Conexao.BeginTransaction

        Comando(0).CommandType = CommandType.StoredProcedure
        Comando(0).Transaction = Transacao
        Comando(0).Parameters.Clear()
        Comando_Log.CommandType = CommandType.StoredProcedure
        Comando_Log.Transaction = Transacao

        NomeSP = SP
        Debug = SP
    End Sub

    Public Sub AddSP(ByVal SP As String)
        ReDim Preserve Comando(Comando.Length)
        Comando(Comando.Length - 1) = New SqlCommand(SP, Conexao)
        Comando(Comando.Length - 1).CommandType = CommandType.StoredProcedure
        Comando(Comando.Length - 1).Transaction = Transacao
        Comando(Comando.Length - 1).Parameters.Clear()

        Debug = SP
    End Sub

    Public Sub addParam(ByVal param As String, ByVal valor As Object, Optional ByVal Com As Integer = 0)
        Comando(Com).Parameters.AddWithValue(param, valor)

        'Try Catch Abaixo Incluído em 14/11/2012 - Por Claudio Shiniti: Devido ao uso do CREATE TYPE no SQL (Tipo de Estrutura de dados próprio), ao enviar um parâmetro DataTable, dá erro na variável debug =. Foi feito um tratamento para evitar o erro.
        Try
            Debug = Debug & vbCrLf & param & " = " & valor & ","
        Catch
            Debug = Debug & vbCrLf & param & "=[Objeto_DataTable]"
        End Try
    End Sub

    Public Sub addParamOutput(ByVal param As String, ByVal sqldbtype As System.Data.SqlDbType, Optional ByVal Com As Integer = 0)
        Comando(Com).Parameters.Add(param, sqldbtype).Direction = ParameterDirection.Output
    End Sub

    Public Sub addParamOutputVarChar(ByVal param As String, ByVal sqldbtype As System.Data.SqlDbType, ByVal tamanho As Integer, Optional ByVal Com As Integer = 0)
        Comando(Com).Parameters.Add(param, sqldbtype, tamanho).Direction = ParameterDirection.Output
    End Sub

    Public Sub Executa(Optional ByVal Com As Integer = 0, Optional ByVal Usuario_Log As Integer = -1000)
        Try
            Comando(Com).ExecuteNonQuery()

            If Mid(Debug, Len(Debug), 1) = "," Then
                Debug = Mid(Debug, 1, Len(Debug) - 1)
            End If

            Dim insLog As New Insere_LOG_Transacao(Comando_Log, Debug, Usuario_Log)
            Debug = NomeSP
        Catch ex As Exception
            Transacao.Rollback()

            Comando(Com).Dispose()
            Conexao.Close()

            HttpContext.Current.Response.Write("Erro Técnico: " & ex.Message & " - Favor entrar em Contato com o Suporte.")
            HttpContext.Current.Response.End()
        End Try
    End Sub

    Public Sub Confirma()
        Try
            Transacao.Commit()
        Catch ex As Exception
            Transacao.Rollback()

            Conexao.Close()
            Conexao.Dispose()
            Conexao = Nothing
            Comando = Nothing
            Comando_Log = Nothing

            HttpContext.Current.Response.Write("Erro Técnico: " & ex.Message & " - Favor entrar em Contato com o Suporte.")
            HttpContext.Current.Response.End()
        End Try

        Conexao.Close()
        Conexao.Dispose()
        Conexao = Nothing
        Comando = Nothing
        Comando_Log = Nothing
    End Sub
End Class

Public Class SelectSP
    Public Conexao As SqlConnection
    Public Comando As SqlCommand
    Public dataAdapter As SqlDataAdapter
    Public sDataTable As DataTable
    Public Transacao As SqlTransaction
    Private ConexaoEnviada As Boolean = False
    Public Debug As String

    Public Sub New(ByVal SP As String, Optional ByRef _Conexao As SqlConnection = Nothing, Optional ByRef _Transacao As SqlTransaction = Nothing)
        If _Conexao Is Nothing Then
            Conexao = Conexao_AC()
        Else
            ConexaoEnviada = True
            Conexao = _Conexao
            Transacao = _Transacao
        End If

        Comando = New SqlCommand(SP, Conexao)
        Comando.CommandType = CommandType.StoredProcedure

        If ConexaoEnviada Then Comando.Transaction = Transacao

        Comando.Parameters.Clear()

        If Not ConexaoEnviada Then
            Conexao.Close()
        End If

        Debug = SP
    End Sub

    Public Sub addParam(ByVal param As String, ByVal valor As Object)
        Comando.Parameters.AddWithValue(param, valor)

        Debug = Debug & vbCrLf & param & " = " & valor & ","
    End Sub

    Public Sub addParamOutput(ByVal param As String, ByVal sqldbtype As System.Data.SqlDbType)
        Comando.Parameters.Add(param, sqldbtype).Direction = ParameterDirection.Output
    End Sub

    Public Sub addParamOutputVarChar(ByVal param As String, ByVal sqldbtype As System.Data.SqlDbType, ByVal tamanho As Integer)
        Comando.Parameters.Add(param, sqldbtype, tamanho).Direction = ParameterDirection.Output
    End Sub

    Public Sub Executa(Optional ByVal Usuario_Log As Integer = -1000)
        Try
            dataAdapter = New SqlDataAdapter()
            sDataTable = New DataTable()
            dataAdapter.SelectCommand = Comando
            dataAdapter.Fill(sDataTable)

            If Mid(Debug, Len(Debug), 1) = "," Then
                Debug = Mid(Debug, 1, Len(Debug) - 1)
            End If

            Dim insLog As New Insere_LOG_Consulta(Conexao, Debug, Usuario_Log, Transacao)
        Catch ex As Exception
            HttpContext.Current.Response.Write("Erro Técnico: " & ex.Message & " - Favor entrar em Contato com o Suporte.")
            HttpContext.Current.Response.End()

            Comando.Dispose()
            Conexao.Close()
        End Try

        Comando.Dispose()
        If Not ConexaoEnviada Then
            Conexao.Close()
        End If
    End Sub
End Class

Public Class Funcoes
    Public Function ResizeImage(ByVal image As Image, ByVal maxWidth As Integer, ByVal maxHeight As Integer) As Image
        If IsDBNull(image) Then
            Return image
        End If
        Dim width As Integer = image.Width
        Dim height As Integer = image.Height

        Dim widthFactor As Double = (Convert.ToDouble(width) / Convert.ToDouble(maxWidth))
        Dim heightFactor As Double = (Convert.ToDouble(height) / Convert.ToDouble(maxHeight))

        If widthFactor <= 1 Then
            'Skip(resize)
            Return image
        Else
            Dim newWidth As Integer
            Dim newHeight As Integer
            If widthFactor > heightFactor Then
                newWidth = Convert.ToInt32(Convert.ToDouble(width) / widthFactor)
                newHeight = Convert.ToInt32(Convert.ToDouble(height) / widthFactor)
            Else
                newWidth = Convert.ToInt32(Convert.ToDouble(width) / heightFactor)
                newHeight = Convert.ToInt32(Convert.ToDouble(height) / heightFactor)
            End If
            If newHeight = 0 Then
                newHeight = 1
            End If
            If newWidth = 0 Then
                newWidth = 1
            End If
            Dim bitmap As Bitmap = New Bitmap(newWidth, newHeight, System.Drawing.Imaging.PixelFormat.Format24bppRgb)
            bitmap.SetResolution(96, 96)

            Dim Graphics As Graphics = Graphics.FromImage(bitmap)
            Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias
            Graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic
            Graphics.DrawImage(image, 0, 0, newWidth, newHeight)
            image.Dispose()
            Return bitmap
        End If
    End Function
End Class

Public Class CarregaCombo
    Public Conexao As SqlConnection
    Public Comando As SqlCommand
    Public dataAdapter As SqlDataAdapter
    Public sDataTable As DataTable

    Public Sub New(ByVal SP As String)
        Conexao = Conexao_AC()
        Comando = New SqlCommand(SP, Conexao)

        Comando.CommandType = CommandType.StoredProcedure
        Comando.Parameters.Clear()
    End Sub

    Public Sub addParam(ByVal param As String, ByVal valor As Object)
        Comando.Parameters.AddWithValue(param, valor)
    End Sub

    Public Sub Executa()
        dataAdapter = New SqlDataAdapter()
        sDataTable = New DataTable()
        dataAdapter.SelectCommand = Comando
        dataAdapter.Fill(sDataTable)
        Comando.Dispose()
        Conexao.Close()
    End Sub

    Public Sub FinalizaCombo(ByVal combo As DropDownList, ByVal campo As String, ByVal texto As String)
        combo.DataSource = sDataTable
        combo.DataValueField = campo
        combo.DataTextField = texto
        combo.DataBind()
    End Sub
End Class

Public Class CarregaComboAjax
    Public Conexao As SqlConnection
    Public Comando As SqlCommand
    Public dataAdapter As SqlDataAdapter
    Public sDataTable As DataTable

    Public Sub New(ByVal SP As String)
        Conexao = Conexao_AC()
        Comando = New SqlCommand(SP, Conexao)

        Comando.CommandType = CommandType.StoredProcedure
        Comando.Parameters.Clear()
    End Sub

    Public Sub addParam(ByVal param As String, ByVal valor As Object)
        Comando.Parameters.AddWithValue(param, valor)
    End Sub

    Public Sub Executa()
        dataAdapter = New SqlDataAdapter()
        sDataTable = New DataTable()
        dataAdapter.SelectCommand = Comando
        dataAdapter.Fill(sDataTable)
        Comando.Dispose()
        Conexao.Close()
    End Sub

    Public Sub FinalizaCombo(ByVal combo As ComboBox, ByVal campo As String, ByVal texto As String)
        combo.DataSource = sDataTable
        combo.DataValueField = campo
        combo.DataTextField = texto
        combo.DataBind()
    End Sub
End Class

Public Class CarregaComboFixo

    Public Sub New(ByVal Tipo As String, ByVal combo As DropDownList)

        Select Case Tipo
            Case "Horario"
                combo.Items.Add("00:00")
                combo.Items.Add("01:00")
                combo.Items.Add("02:00")
                combo.Items.Add("03:00")
                combo.Items.Add("04:00")
                combo.Items.Add("05:00")
                combo.Items.Add("06:00")
                combo.Items.Add("07:00")
                combo.Items.Add("08:00")
                combo.Items.Add("09:00")
                combo.Items.Add("10:00")
                combo.Items.Add("11:00")
                combo.Items.Add("12:00")
                combo.Items.Add("13:00")
                combo.Items.Add("14:00")
                combo.Items.Add("15:00")
                combo.Items.Add("16:00")
                combo.Items.Add("17:00")
                combo.Items.Add("18:00")
                combo.Items.Add("19:00")
                combo.Items.Add("20:00")
                combo.Items.Add("21:00")
                combo.Items.Add("22:00")
                combo.Items.Add("23:00")

            Case "Semana"
                combo.Items.Add("Segunda - feira")
                combo.Items(0).Value = 2
                combo.Items.Add("Terça - feira")
                combo.Items(1).Value = 3
                combo.Items.Add("Quarta - feira")
                combo.Items(2).Value = 4
                combo.Items.Add("Quinta - feira")
                combo.Items(3).Value = 5
                combo.Items.Add("Sexta - feira")
                combo.Items(4).Value = 6
                combo.Items.Add("Sábado")
                combo.Items(5).Value = 7
                combo.Items.Add("Domingo")
                combo.Items(6).Value = 1

            Case "StatusFatura"
                combo.Items.Add("Em Aberto")
                combo.Items(0).Value = 1
                combo.Items.Add("À Integrar")
                combo.Items(1).Value = 2
                combo.Items.Add("Integrados")
                combo.Items(2).Value = 3
                combo.Items.Add("Liquidados")
                combo.Items(3).Value = 4

            Case "Mes"
                combo.Items.Add("Janeiro")
                combo.Items(0).Value = 1
                combo.Items.Add("Fevereiro")
                combo.Items(1).Value = 2
                combo.Items.Add("Março")
                combo.Items(2).Value = 3
                combo.Items.Add("Abril")
                combo.Items(3).Value = 4
                combo.Items.Add("Maio")
                combo.Items(4).Value = 5
                combo.Items.Add("Junho")
                combo.Items(5).Value = 6
                combo.Items.Add("Julho")
                combo.Items(6).Value = 7
                combo.Items.Add("Agosto")
                combo.Items(7).Value = 8
                combo.Items.Add("Setembro")
                combo.Items(8).Value = 9
                combo.Items.Add("Outubro")
                combo.Items(9).Value = 10
                combo.Items.Add("Novembro")
                combo.Items(10).Value = 11
                combo.Items.Add("Dezembro")
                combo.Items(11).Value = 12

            Case "Download"
                combo.Items.Add("Arquivo Selecionado")
                combo.Items(0).Value = 1
                combo.Items.Add("Link Direto de Outro Site")
                combo.Items(1).Value = 2

            Case "TipoCheckout"
                combo.Items.Add("-- Selecione --")
                combo.Items(0).Value = -1
                combo.Items.Add("Pin Pad Alugado Rede")
                combo.Items(1).Value = 1
                combo.Items.Add("Pin Pad Alugado Cielo")
                combo.Items(2).Value = 2
                combo.Items.Add("Pin Pad Próprio")
                combo.Items(3).Value = 0

            Case "TipoSolicitacaoRede"
                combo.Items.Add("-- Selecione --")
                combo.Items(0).Value = -1
                combo.Items.Add("Geração de N° Lógico")
                combo.Items(1).Value = 1
                combo.Items.Add("Desinstalação de N° Lógico")
                combo.Items(2).Value = 2
                combo.Items.Add("Instalação de Tecnologia")
                combo.Items(3).Value = 3
                combo.Items.Add("Troca de Tecnologia")
                combo.Items(4).Value = 4
                combo.Items.Add("Desinstalação de Tecnologia")
                combo.Items(5).Value = 5
        End Select

    End Sub
End Class

Public Class CarregaComboFixoAjax

    Public Sub New(ByVal Tipo As String, ByVal combo As ComboBox)

        Select Case Tipo
            Case "Horario"
                combo.Items.Add("00:00")
                combo.Items.Add("01:00")
                combo.Items.Add("02:00")
                combo.Items.Add("03:00")
                combo.Items.Add("04:00")
                combo.Items.Add("05:00")
                combo.Items.Add("06:00")
                combo.Items.Add("07:00")
                combo.Items.Add("08:00")
                combo.Items.Add("09:00")
                combo.Items.Add("10:00")
                combo.Items.Add("11:00")
                combo.Items.Add("12:00")
                combo.Items.Add("13:00")
                combo.Items.Add("14:00")
                combo.Items.Add("15:00")
                combo.Items.Add("16:00")
                combo.Items.Add("17:00")
                combo.Items.Add("18:00")
                combo.Items.Add("19:00")
                combo.Items.Add("20:00")
                combo.Items.Add("21:00")
                combo.Items.Add("22:00")
                combo.Items.Add("23:00")

            Case "Semana"
                combo.Items.Add("Segunda - feira")
                combo.Items(0).Value = 2
                combo.Items.Add("Terça - feira")
                combo.Items(1).Value = 3
                combo.Items.Add("Quarta - feira")
                combo.Items(2).Value = 4
                combo.Items.Add("Quinta - feira")
                combo.Items(3).Value = 5
                combo.Items.Add("Sexta - feira")
                combo.Items(4).Value = 6
                combo.Items.Add("Sábado")
                combo.Items(5).Value = 7
                combo.Items.Add("Domingo")
                combo.Items(6).Value = 1

            Case "StatusFatura"
                combo.Items.Add("Em Aberto")
                combo.Items(0).Value = 1
                combo.Items.Add("À Integrar")
                combo.Items(1).Value = 2
                combo.Items.Add("Integrados")
                combo.Items(2).Value = 3
                combo.Items.Add("Liquidados")
                combo.Items(3).Value = 4

            Case "Mes"
                combo.Items.Add("Janeiro")
                combo.Items(0).Value = 1
                combo.Items.Add("Fevereiro")
                combo.Items(1).Value = 2
                combo.Items.Add("Março")
                combo.Items(2).Value = 3
                combo.Items.Add("Abril")
                combo.Items(3).Value = 4
                combo.Items.Add("Maio")
                combo.Items(4).Value = 5
                combo.Items.Add("Junho")
                combo.Items(5).Value = 6
                combo.Items.Add("Julho")
                combo.Items(6).Value = 7
                combo.Items.Add("Agosto")
                combo.Items(7).Value = 8
                combo.Items.Add("Setembro")
                combo.Items(8).Value = 9
                combo.Items.Add("Outubro")
                combo.Items(9).Value = 10
                combo.Items.Add("Novembro")
                combo.Items(10).Value = 11
                combo.Items.Add("Dezembro")
                combo.Items(11).Value = 12
        End Select

    End Sub
End Class

Public Class Global_DataTable
    Public DT As DataTable

    Public Sub New()

    End Sub
End Class

Public Class Envia_Email
    Public Remetente As String
    Public Senha As String
    Public Server As String
    Public Destinatario As String
    Public CC As String
    Public CCO As String
    Public Assunto As String
    Public Anexo(10) As String
    Public Corpo As String


    Public Sub New()

    End Sub

    Function Finaliza(Optional GMail As Boolean = True) As Boolean
        Dim FlagEmail As String = System.Configuration.ConfigurationManager.AppSettings("FlagEmail")
        Dim K As Integer

Reenvia_Novo_Remetente:

        Dim SelParametros As New SelectSP("AC_SP_SEL_PARAMETROS")

        SelParametros.Executa()

        Dim RemetenteAtual As String = SelParametros.sDataTable.Rows(0)("PAR_REMETENTE_ATUAL")

        Dim EMail As New System.Net.Mail.MailMessage()
        'EMail.From = Remetente
        'Deixado remetente fixo para gmail
        'Remetente = "elgautomacao@gmail.com"
        Remetente = RemetenteAtual
        EMail.From = New System.Net.Mail.MailAddress(Remetente, "sistema@elginautomacao.com.br")

        Dim emailFlagZero As String
        emailFlagZero = "claudiosy@hotmail.com"

        Dim rgx As New Regex("(;)")
        Dim s As String()
        If FlagEmail = "0" Then
            s = rgx.Split(emailFlagZero)
            For i = 0 To s.Count - 1
                emailFlagZero = s(i)
                If emailFlagZero <> ";" Then
                    EMail.To.Add("<" & emailFlagZero & ">")
                End If
            Next

        Else
            'Atribui ao método To o valor do Destinatário
            'EMail.To = Destinatario
            If Destinatario <> "" Then
                s = rgx.Split(Destinatario)
                For i = 0 To s.Count - 1
                    Destinatario = s(i)
                    If Destinatario <> ";" And Destinatario <> "" Then
                        EMail.To.Add("<" & Destinatario & ">")
                    End If
                Next
            End If
            '

            'Atribui ao método Cc o valor do com Cópia
            'EMail.Cc = CC
            If CC <> "" Then
                s = rgx.Split(CC)
                For i = 0 To s.Count - 1
                    CC = s(i)
                    If CC <> ";" And CC <> "" Then
                        EMail.CC.Add("<" & CC & ">")
                    End If
                Next
            End If



            'Atribui ao método Bcc o valor do com Cópia oculta
            'EMail.Bcc = CCO
            If CCO <> "" Then
                s = rgx.Split(CCO)
                For i = 0 To s.Count - 1
                    CCO = s(i)
                    If CCO <> ";" And CCO <> "" Then
                        EMail.Bcc.Add("<" & CCO & ">")
                    End If
                Next
            End If


        End If
        'Atribui o assunto da mensagem
        EMail.Subject = Assunto

        'Define o formato da mensagem que pode ser Texto ou Html
        'EMail.BodyFormat = MailFormat.Html]
        EMail.IsBodyHtml = True


        Dim CorpoTotal = "<html>" &
                    "<body>" &
                        "<table border='0' cellspacing='0' cellpadding='0' width='653'>" &
                            "<tr>" &
                                "<td width='653'><div align='left' ><img  src='http://www.elginautomacao.com.br/ac/imagens/logos/LogoCabecalho.jpg' />" &
                                "<hr size='2' width='100%' align='center' />" &
                                "<p>*** Esse é um email automático. Não é necessário respondê-lo ***</p>" &
                                Corpo &
                                "<hr size='2' width='100%' align='center'/></div><p>" &
                                "<p><img  src='http://www.elginautomacao.com.br/ac/imagens/logos/LogoCabecalho.jpg' /><br />" &
                                "<br />" &
                                "<font size='-1'>Rua Barão de Campinas,305 - Centro<br />" &
                                    "São Paulo&nbsp;- SP&nbsp;- Brasil<br />" &
                                    "CEP 01201-901<br />" &
                                "</font>" &
                                "</p>" &
                            "</tr>" &
                        "</table>" &
                    "</body>" &
                "</html>"


        '"Tel.: (55) (11) 3789-2978" & _
        '"</font>" & _
        '"<br />" & _
        '"Fax.: (55) (11) 3789-2976 </p>" & _
        '"<table border='0' cellspacing='0' cellpadding='0' width='614'>" & _
        '"<tr>" & _
        '  "<td>" & _
        '  "<p><a href='http://www.elgin.com.br/automacao' target='_blank'><img border='0' width='77' height='118' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c1.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c1.png' /></a></td>" & _
        '  "<td><p><a href='http://www.elgin.com.br/portalelgin/Site/Contato/Suporte/FaleConosco.aspx?Divisao=1&amp;sm=cbfc_1' target='_blank'><img border='0' width='76' height='118' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c2.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c2.png' /></a></p></td>" & _
        '  "<td><p><a href='http://www.elgin.com.br/portalelgin/Site/MarketingPersonalizado/MktPersonalizado.aspx?Divisao=1&amp;sm=cbfa_1' target='_blank'><img border='0' width='77' height='118' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c3.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c3.png' /></a></p></td>" & _
        '  "<td><p><a href='http://www.elgin.com.br/ftp/gecare/inova/index.html' target='_blank'><img border='0' width='76' height='118' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c4.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c4.png' /></a></p></td>" & _
        '  "<td><p><a href='http://www.orkut.com.br/Main#Profile?uid=16832816878612151100&amp;rl=t' target='_blank'><img border='0' width='78' height='118' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c5.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c5.png' /></a></p></td>" & _
        '  "<td><p><a href='http://www.youtube.com/user/ElginAutomacao' target='_blank'><img border='0' width='76' height='118' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c6.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c6.png' /></a></p></td>" & _
        '  "<td><p><a href='http://twitter.com/elginautomacao' target='_blank'><img border='0' width='77' height='118' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c7.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c7.png' /></a></p></td>" & _
        '  "<td><p><a href='http://www.facebook.com/#!/profile.php?id=100001182235389' target='_blank'><img border='0' width='77' height='118' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c8.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/elgin_r1_c8.png' /></a></p></td>" & _
        ' "</tr>" & _
        '"</table>" & _
        '"<p><strong><br />" & _
        '    "</strong><Font size='-1'> Esta mensagem, incluindo seus anexos, tem caráter confidencial    e seu conteúdo é restrito ao destinatário da mensagem. Caso você tenha    recebido esta mensagem por engano, queira por favor retorná-la ao    destinatário e apagá-la de seus arquivos. Qualquer uso não autorizado,    replicação ou disseminação desta mensagem ou parte dela é expressamente    proibido. A&nbsp;ELGIN não é responsável pelo conteúdo ou a veracidade desta    informação.</Font><br />" & _
        '    "<br />" & _
        '"<strong><img border='0' width='100' height='58' src='http://www.elgin.com.br/ftp/gecare/assinatura_mail/lampada2.png' alt='http://www.elgin.com.br/ftp/gecare/assinatura_mail/lampada2.png' /></strong><strong><font size='-1' color='#009933'>Pense    antes de imprimir. Preservar os recursos naturais do planeta é nossa    responsabilidade.</font></strong></p></td>" & _
        '"</tr>" & _
        '"</table>" & _
        '    "</body>"


        'Atribui ao método Body a texto da mensagem
        EMail.Body = CorpoTotal

        EMail.SubjectEncoding = System.Text.Encoding.GetEncoding("ISO-8859-1")
        EMail.BodyEncoding = System.Text.Encoding.GetEncoding("ISO-8859-1")

        'Dim Attachment As New System.Net.Mail.Attachment

        'For i = 0 To lstAnexos.Items.Count - 1
        '    Mailmsg.Attachments.Add(New Attachment(lstAnexos.Items(i)))
        'Next

        'Dim MyMessage As MailMessage = New MailMessage()
        'MyMessage.Attachments.Add(New MailAttachment(fileName1))
        'Anexa a Planilha Excel Gerada

        Dim Arq_Anexo As Attachment 'Variável criado em 09/06/2013 - Por Claudio Shiniti: Cria o Objeto Attachment separado, para poder fechar ao término do envio do e-mail, para evitar que o arquivo fique preso em memória e em processo (EX: Planilha da SWE MultiLoja)

        For K = 0 To Anexo.Length - 1
            If Trim(Anexo(K) <> "") Then
                Arq_Anexo = New Attachment(Anexo(K))
                EMail.Attachments.Add(Arq_Anexo)
                'EMail.Attachments.Add(New Attachment("c:\Inventario_Prosoft.HTML"))

            Else
                Exit For
            End If
        Next


        'AUTENTICACAO NO SERVIDOR DE EMAIL  
        'If Not IsNothing(User.Identity) Then
        'EMail.Fields("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = 1
        'EMail.Fields("http://schemas.microsoft.com/cdo/configuration/sendusername") = Remetente
        'EMail.Fields("http://schemas.microsoft.com/cdo/configuration/sendpassword") = Senha
        'End If

        'Colocado Server fixo para o gmail
        'Server = "smtp.gmail.com"
        Server = "smtp.klariontech.com.br"

        Dim objSmtp As New SmtpClient(Server, 587)

        'If GMail Then 'If Incluído em 12/08/2014 - Por Claudio Shiniti: Criado parâmetro opcional para enviar com GMail, pois a locaweb está muito lento para mandar emails, provocando erros por time out
        'objSmtp.EnableSsl = True
        'End If

        'Alocamos o endereço do host para enviar os e-mails  
        objSmtp.Credentials = New System.Net.NetworkCredential(Remetente, Senha)
        objSmtp.Host = Server
        objSmtp.Port = 587

        'Define qual o host a ser usado para envio de mensagens, 
        'SmtpMail.SmtpServer = Server

        'Envia a mensagem 
        Try
            objSmtp.Send(EMail)

            EMail.Attachments.Clear()
            If Not Arq_Anexo Is Nothing Then
                Arq_Anexo.Dispose()
            End If
            EMail.Dispose()
            EMail = Nothing
            'SmtpMail.Send(EMail)
            Return True
        Catch ex As Exception
            Dim dtNow, dtUltimaTroca As DateTime

            dtNow = DataHora_Hoje(CType(ConfigurationManager.AppSettings("FusoHorario"), Integer))
            dtUltimaTroca = SelParametros.sDataTable.Rows(0)("PAR_ULTIMA_TROCA_REMETENTE")

            If (dtNow - dtUltimaTroca).TotalMinutes() > 70 Then
                If RemetenteAtual = "elginautomacao1@klariontech.com.br" Then
                    RemetenteAtual = "elginautomacao2@klariontech.com.br"
                ElseIf RemetenteAtual = "elginautomacao2@klariontech.com.br" Then
                    RemetenteAtual = "elginautomacao3@klariontech.com.br"
                ElseIf RemetenteAtual = "elginautomacao3@klariontech.com.br" Then
                    RemetenteAtual = "elginautomacao1@klariontech.com.br"
                End If

                Dim UpdParametros As New ExecutaSP("AC_SP_UPD_PAR_REMETENTE")
                UpdParametros.addParam("@PROXIMO_REMETENTE", RemetenteAtual)
                UpdParametros.Executa()
                UpdParametros.Confirma()

                GoTo Reenvia_Novo_Remetente
            End If

            EMail.Attachments.Clear()
            If Not Arq_Anexo Is Nothing Then
                Arq_Anexo.Dispose()
            End If
            EMail.Dispose()
            EMail = Nothing

            Return False
        End Try
        EMail.Dispose()
    End Function

End Class

Public Class Criptografia
    Private chave As Byte() = {}
    Private iv As Byte() = {12, 34, 56, 78, 90, 102, 114, 126}

    Public Sub New()

    End Sub

    Function Criptografar(ByVal valor As String, ByVal chaveCriptografia As String) As String
        Dim des As DESCryptoServiceProvider
        Dim ms As MemoryStream
        Dim cs As CryptoStream
        Dim input As Byte()

        Try
            des = New DESCryptoServiceProvider()
            ms = New MemoryStream()

            input = Encoding.UTF8.GetBytes(valor)
            chave = Encoding.UTF8.GetBytes(Mid(chaveCriptografia, 1, 8))
            cs = New CryptoStream(ms, des.CreateEncryptor(chave, iv), CryptoStreamMode.Write)
            cs.Write(input, 0, input.Length)
            cs.FlushFinalBlock()

            Return Convert.ToBase64String(ms.ToArray())
        Catch ex As Exception
            Return "Erro"
        End Try
    End Function

    Function Descriptografar(ByVal valor As String, ByVal chaveCriptografia As String) As String
        Dim des As DESCryptoServiceProvider
        Dim ms As MemoryStream
        Dim cs As CryptoStream
        Dim input As Byte()

        Try
            des = New DESCryptoServiceProvider()
            ms = New MemoryStream()

            input = New Byte(valor.Length) {}
            input = Convert.FromBase64String(valor.Replace(" ", "+"))
            chave = Encoding.UTF8.GetBytes(Mid(chaveCriptografia, 1, 8))

            cs = New CryptoStream(ms, des.CreateDecryptor(chave, iv), CryptoStreamMode.Write)
            cs.Write(input, 0, input.Length)
            cs.FlushFinalBlock()

            Return Encoding.UTF8.GetString(ms.ToArray())
        Catch ex As Exception
            Return "Erro"
        End Try
    End Function



End Class
Public Class Autenticacao
    Public Login As String
    Public Senha As String

    Public Sub New()

    End Sub
End Class

Public Class Chama_pagina
    Private caminho As String

    Public Sub New(ByVal url As String)
        caminho = url & "?"
    End Sub

    Public Sub addParam(ByVal nome As String, ByVal conteudo As String, Optional ByVal criptografa As Boolean = True)
        Dim criptografia As New Criptografia
        If criptografa Then
            caminho &= nome & "=" & criptografia.Criptografar(conteudo, "14061910") & "&"
        Else
            caminho &= nome & "=" & conteudo & "&"
        End If


    End Sub

    Public Function load(Optional novaJanela As Boolean = False) As String

        caminho = Mid(caminho, 1, Len(caminho) - 1)
        If novaJanela = False Then

            HttpContext.Current.Response.Redirect(caminho)
        End If


        Return caminho
    End Function

End Class

Public Class Insere_LOG_Transacao
    Public Sub New(ByVal vlComando As SqlCommand, ByVal vlEvento As String, ByVal Usuario_Log As Integer)
        Dim vlUsuario_Log As Integer

        If Usuario_Log = -1000 Then 'Caso não for informado o código do usuário no Executa (Parâmetro Opcional), usa a sessão, desde que não esteja nothing
            If HttpContext.Current.Session("vg_id_usuario") <> Nothing Then
                vlUsuario_Log = HttpContext.Current.Session("vg_id_usuario")
            Else
                Exit Sub
            End If
        Else 'Caso for informado o código do usuário no Executa (Parâmetro Opcional), usa esse código pra registrar o Log (No caso de cliente, ou webservice)
            vlUsuario_Log = Usuario_Log
        End If

        vlComando.Parameters.Clear()
        vlComando.Parameters.AddWithValue("@LOG_USUCODIGO", vlUsuario_Log)
        vlComando.Parameters.AddWithValue("@LOG_IP", HttpContext.Current.Request.UserHostAddress)
        vlComando.Parameters.AddWithValue("@LOG_BASE", "elginautomacao")
        vlComando.Parameters.AddWithValue("@LOG_TIPO", "T")
        vlComando.Parameters.AddWithValue("@LOG_EVENTO", vlEvento)
        vlComando.Parameters.AddWithValue("@LOG_PAGINA", CarregaNomeArquivo)

        vlComando.ExecuteNonQuery()
    End Sub
End Class

Public Class Insere_LOG_Consulta
    Public Sub New(ByVal vlConexao As SqlConnection, ByVal vlEvento As String, ByVal Usuario_Log As Integer, Optional ByRef vlTransacao As SqlTransaction = Nothing)
        Dim vlUsuario_Log As Integer

        If Usuario_Log = -1000 Then 'Caso não for informado o código do usuário no Executa (Parâmetro Opcional), usa a sessão, desde que não esteja nothing
            If HttpContext.Current.Session("vg_id_usuario") <> Nothing Then
                vlUsuario_Log = HttpContext.Current.Session("vg_id_usuario")
            Else
                Exit Sub
            End If
        Else 'Caso for informado o código do usuário no Executa (Parâmetro Opcional), usa esse código pra registrar o Log (No caso de cliente, ou webservice)
            vlUsuario_Log = Usuario_Log
        End If

        If vlConexao.State = ConnectionState.Closed Then
            vlConexao.Open()
        End If

        Dim vlComando As New SqlCommand("AC_SP_INS_LOG", vlConexao)
        vlComando.CommandType = CommandType.StoredProcedure

        If Not vlTransacao Is Nothing Then
            vlComando.Transaction = vlTransacao
        End If

        vlComando.Parameters.Clear()
        vlComando.Parameters.AddWithValue("@LOG_USUCODIGO", vlUsuario_Log)
        vlComando.Parameters.AddWithValue("@LOG_IP", HttpContext.Current.Request.UserHostAddress)
        vlComando.Parameters.AddWithValue("@LOG_BASE", "elginautomacao")
        vlComando.Parameters.AddWithValue("@LOG_TIPO", "C")
        vlComando.Parameters.AddWithValue("@LOG_EVENTO", vlEvento)
        vlComando.Parameters.AddWithValue("@LOG_PAGINA", CarregaNomeArquivo)

        vlComando.ExecuteNonQuery()

        vlComando.Dispose()
        vlComando = Nothing
    End Sub
End Class

Public Class Insere_LOG_Sygma
    Public Sub New(ByVal vlEvento As String)
        If HttpContext.Current.Session("vg_id_usuario") <> Nothing Then
            Dim vlConexao As SqlConnection
            Dim Tipo As String = "C"

            vlConexao = Conexao_AC()
            vlConexao.Open()

            Dim vlComando As New SqlCommand("AC_SP_INS_LOG", vlConexao)
            vlComando.CommandType = CommandType.StoredProcedure

            If LCase(vlEvento).IndexOf("insert") = "0" Or LCase(vlEvento).IndexOf("update") = "0" Or LCase(vlEvento).IndexOf("delete") = "0" Then
                Tipo = "T"
            End If

            vlComando.Parameters.Clear()
            vlComando.Parameters.AddWithValue("@LOG_USUCODIGO", HttpContext.Current.Session("vg_id_usuario"))
            vlComando.Parameters.AddWithValue("@LOG_IP", HttpContext.Current.Request.UserHostAddress)
            vlComando.Parameters.AddWithValue("@LOG_BASE", "sygma")
            vlComando.Parameters.AddWithValue("@LOG_TIPO", Tipo)
            vlComando.Parameters.AddWithValue("@LOG_EVENTO", vlEvento)
            vlComando.Parameters.AddWithValue("@LOG_PAGINA", CarregaNomeArquivo)

            vlComando.ExecuteNonQuery()

            vlConexao.Close()
            vlConexao.Dispose()
            vlConexao = Nothing
            vlComando.Dispose()
            vlComando = Nothing
        End If
    End Sub
End Class


Public Class geraPlanilhaExl
    Private gv As GridView
    Private _nomeplanilha As String = "Planilha.xls"
    Public Property nomeplanilha() As String
        Get
            Return _nomeplanilha

        End Get
        Set(value As String)
            If Trim(value) = "" Then
                Throw New Exception("Valor vazio")
            End If

            _nomeplanilha = value
        End Set
    End Property

    Public Sub DataTableToExcel(ByRef dt As DataTable)
        gv = New GridView()
        ' Formatação do GridView para que a planilha fique "zebrada"

        gv.HeaderStyle.ForeColor = Color.Blue
        gv.AlternatingRowStyle.BackColor = Color.AliceBlue
        gv.RowStyle.BackColor = Color.White
        If gv.Rows.Count < 65536 Or gv.Rows.Count = 0 Then
            Dim response As HttpResponse = HttpContext.Current.Response
            response.Clear()
            If nomeplanilha = "Planilha.xls" Then
                response.AddHeader("Content-Disposition", "attachment; filename=Planilha.xls")
            Else
                If nomeplanilha.EndsWith(".xls") Then
                    response.AddHeader("Content-Disposition", "attachment; filename=" & nomeplanilha)
                Else
                    response.AddHeader("Content-Disposition", "attachment; filename=" & nomeplanilha & ".xls")
                End If
            End If

            response.ContentType = "application/vnd.ms-excel"
            Dim stringWrite As New StringWriter
            Dim htmlWrite As New HtmlTextWriter(stringWrite)
            gv.DataSource = dt
            gv.DataBind()
            gv.RenderControl(htmlWrite)
            response.Write(stringWrite.ToString)
            response.End()
        Else
            ' se tiver mais que 65536 linhas, dispara a exception
            Throw New Exception("Consulta deve conter menos que 65536 linhas")
        End If
    End Sub
End Class
Public Class emailPendente_Gerente
    Public gerenteUsuCodigo As String
    Public Usuario As String
    Public numeroPedido As String
    Public linPedido As String
    Public razaoRevenda As String
    Public nomeFantasiaRevenda As String

    Public Sub New()

    End Sub

    Function EnviaGerente() As Boolean
        Dim gerente As New SelectSP("AC_SP_SEL_USUARIOS")
        gerente.addParam("@USU_CODIGO", gerenteUsuCodigo)
        gerente.Executa()

        If gerente.sDataTable.Rows.Count = 0 Then 'If Incluído em 29/11/2016 - Por Claudio Shiniti: Caso o gerente não existir mais no cadastro, avisa em mensagem amigável ao usuário, e não erro técnico.
            Throw New Exception("Não existe gerente regional cadastrado para essa revenda.")
        End If

        Dim email As New Envia_Email

        email.Remetente = "elgautomacao@gmail.com"
        email.Destinatario = gerente.sDataTable.Rows(0)("USU_EMAIL")
        email.CCO = "sistema@klariontech.com.br"
        email.Assunto = "Pedido: " & numeroPedido & " - " & linPedido
        email.Corpo = "Pedido de " & linPedido & "<BR>" & "<BR>" & "Razão Social Revenda: " & razaoRevenda & "<BR>" & "Nome Fantasia Revenda: " & nomeFantasiaRevenda & "<BR>" & "Pedido foi feito por: " & Usuario & "<BR>" & "Data: " & Date.Now & "<BR>" & "Numero do Pedido:" & numeroPedido & "<BR>" & "Acesse o site <a href='http://www.elginautomacao.com.br/'>http://www.elginautomacao.com.br/</a> e verifique o pedido<br>Suporte: 0800 707 5447<br><br>Status: Pendente com Gerente"
        email.Server = "smtp.gmail.com"
        email.Senha = "elgaut3493@#$"

        Try
            email.Finaliza(True)

        Catch
            Return False
        End Try
        Return True
    End Function
End Class

Public Class Gsurfws
    Private gs As Object
    Private autenticacao As Object
    Public resposta As Object
    Private dadosusuario As Object
    Private politica As Object
    Private dadoscliente As Object
    Public respostarevenda As Object
    Private PermissaoCategoria As Object
    Private Permissao As Object







    Public Sub New(usuario As String, ByVal token As String, ByVal wsUser As String, ByVal valor As Integer)


        If valor = 0 Then
            gs = New Gsurf_Homolog.WSGSurfNetPortTypeClient
            autenticacao = New Gsurf_Homolog.Autenticacao
            resposta = New Gsurf_Homolog.Resposta
            dadosusuario = New Gsurf_Homolog.DadosUsuario
            politica = New Gsurf_Homolog.Politica()
            dadoscliente = New Gsurf_Homolog.DadosCliente
            respostarevenda = New Gsurf_Homolog.RespostaRevenda
            Permissao = New Gsurf_Homolog.Permissao
            PermissaoCategoria = New Gsurf_Homolog.PermissaoCategoria
        Else
            gs = New Gsurf_Principal.WSGSurfNetPortTypeClient
            autenticacao = New Gsurf_Principal.Autenticacao
            resposta = New Gsurf_Principal.Resposta
            dadosusuario = New Gsurf_Principal.DadosUsuario
            politica = New Gsurf_Principal.Politica()
            dadoscliente = New Gsurf_Principal.DadosCliente
            respostarevenda = New Gsurf_Principal.RespostaRevenda
            Permissao = New Gsurf_Principal.Permissao
            PermissaoCategoria = New Gsurf_Principal.PermissaoCategoria
        End If
        System.Net.ServicePointManager.Expect100Continue = False

        autenticacao.usuario = usuario
        autenticacao.token = token
        autenticacao.wsUser = wsUser
    End Sub

    Public Function Terminais(ByVal cnpjcli As String) As String()
        Dim retorno As String()

        retorno = gs.terminais(autenticacao, cnpjcli)

        Return retorno

    End Function

    Public Function Revenda(ByVal empresa As DataTable, ByVal usuario As DataTable, _
                            cpf As String) As ArrayList

        Dim cnpj As String = empresa(0)("EMP_CNPJ")
        cnpj = cnpj.Replace(".", "").Replace("-", "").Replace("/", "").Replace("\", "") _
                                    .Replace("_", "")


        dadoscliente.bairro = removeAcentos(empresa(0)("EMP_BAIRRO"))
        dadoscliente.bairroCob = removeAcentos(empresa(0)("EMP_BAIRRO"))
        dadoscliente.cep = empresa(0)("EMP_CEP")
        dadoscliente.cepCob = empresa(0)("EMP_CEP")
        dadoscliente.cidade = removeAcentos(empresa(0)("EMP_CIDADE"))
        dadoscliente.cidadeCob = removeAcentos(empresa(0)("EMP_CIDADE"))
        dadoscliente.cnpj = cnpj
        dadoscliente.contato = empresa(0)("EMP_NOMECONTATO")
        dadoscliente.cpfResponsavel = cpf
        dadoscliente.ddd = empresa(0)("EMP_DDDTELEFONE")
        dadoscliente.ddd2 = empresa(0)("EMP_DDDTELEFONE")
        dadoscliente.email = empresa(0)("EMP_EMAIL")
        dadoscliente.fantasia = removeAcentos(empresa(0)("EMP_NOMEFANTASIA"))
        dadoscliente.inscEstadual = empresa(0)("EMP_IE")
        dadoscliente.logradouro = removeAcentos(empresa(0)("EMP_ENDERECO"))
        dadoscliente.logradouroCob = removeAcentos(empresa(0)("EMP_ENDERECO"))
        dadoscliente.numero = empresa(0)("EMP_NUMERO")
        dadoscliente.numeroCob = empresa(0)("EMP_NUMERO")
        dadoscliente.razao = removeAcentos(empresa(0)("EMP_RAZAOSOCIAL"))
        dadoscliente.responsavel = empresa(0)("EMP_RESPONSAVEL_LEGAL")
        dadoscliente.telefone = empresa(0)("EMP_TELEFONE")
        dadoscliente.telefone2 = empresa(0)("EMP_TELEFONE")
        dadoscliente.uf = empresa(0)("EMP_UF")
        dadoscliente.ufCob = empresa(0)("EMP_UF")


        'Esse usuario primeiro é o que tera permissao de escrita na GSURF <Usado no WS >
        dadosusuario.bairro = removeAcentos(empresa(0)("EMP_BAIRRO"))
        dadosusuario.cep = empresa(0)("EMP_CEP")
        dadosusuario.cidade = removeAcentos(empresa(0)("EMP_CIDADE"))
        dadosusuario.complemento = "Não Possui"
        dadosusuario.cpf = cpf
        dadosusuario.ddd = empresa(0)("EMP_DDDTELEFONE")
        dadosusuario.ddd2 = empresa(0)("EMP_DDDTELEFONE")
        dadosusuario.email = "sistema@klariontech.com.br"
        dadosusuario.logradouro = removeAcentos(empresa(0)("EMP_ENDERECO"))
        dadosusuario.nome = usuario(0)("USU_NOME")
        dadosusuario.numero = usuario(0)("USU_NUMERO")
        dadosusuario.telefone = empresa(0)("EMP_TELEFONE")
        dadosusuario.telefone2 = empresa(0)("EMP_TELEFONE")
        dadosusuario.uf = empresa(0)("EMP_UF")
        dadosusuario.usuario = "elg" & cnpj
        'Senha aleatoria
        Dim gera As New Random
        Dim senha As String = gera.Next(100000000, 900000000).ToString
        dadosusuario.senha = senha
        Dim arr As New ArrayList
        Try


            respostarevenda = gs.revenda(autenticacao, dadoscliente, dadosusuario)


            arr.Add(respostarevenda.retorno)
            arr.Add(respostarevenda.mensagem)
            If arr(0) Then
                arr.Add(respostarevenda.dados.token)
                arr.Add(respostarevenda.dados.usuario)
                arr.Add(respostarevenda.dados.wsUser)
                arr.Add(senha)
            End If


        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try




        Return arr
    End Function

    Public Function AddPoliticaRevenda(ByVal cnpj As String, ByVal politica As Integer) As ArrayList
        Dim arr As New ArrayList



        Try
            resposta = gs.addPoliticaRevenda(autenticacao, cnpj, politica)
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)
        Return arr
    End Function

    Public Function Cadastro(dadoscli As DataTable, idpoli As Integer) As ArrayList
        Dim arr As New ArrayList

        dadoscliente.cnpj = dadoscli(0)("CLI_CNPJ")
        dadoscliente.razao = removeAcentos(dadoscli(0)("CLI_RAZAO_SOCIAL"))
        dadoscliente.fantasia = removeAcentos(dadoscli(0)("CLI_NOME_FANTASIA"))
        dadoscliente.inscEstadual = dadoscli(0)("CLI_IE")
        dadoscliente.responsavel = dadoscli(0)("CLI_NOME_PROPRIETARIO")
        dadoscliente.cpfResponsavel = "178.736.452-66"
        dadoscliente.contato = removeAcentos(dadoscli(0)("CLI_CONTATO"))
        dadoscliente.logradouro = removeAcentos(dadoscli(0)("CLI_ENDERECO"))
        dadoscliente.numero = dadoscli(0)("CLI_NUMERO")
        dadoscliente.bairro = removeAcentos(dadoscli(0)("CLI_BAIRRO"))
        dadoscliente.complemento = removeAcentos(dadoscli(0)("CLI_COMPLEMENTO"))
        dadoscliente.uf = dadoscli(0)("CLI_UF")
        dadoscliente.cidade = removeAcentos(dadoscli(0)("CLI_CIDADE"))
        dadoscliente.cep = dadoscli(0)("CLI_CEP")
        dadoscliente.ddd = dadoscli(0)("CLI_DDDTELEFONE")
        dadoscliente.telefone = dadoscli(0)("CLI_TELEFONE")
        dadoscliente.ddd2 = dadoscli(0)("CLI_DDDTELEFONE")
        dadoscliente.telefone2 = dadoscli(0)("CLI_TELEFONE")
        dadoscliente.email = dadoscli(0)("CLI_EMAIL")
        dadoscliente.logradouroCob = removeAcentos(dadoscli(0)("CLI_ENDERECO"))
        dadoscliente.numeroCob = dadoscli(0)("CLI_NUMERO")
        dadoscliente.bairroCob = removeAcentos(dadoscli(0)("CLI_BAIRRO"))
        dadoscliente.complementoCob = dadoscli(0)("CLI_COMPLEMENTO")
        dadoscliente.ufCob = dadoscli(0)("CLI_UF")
        dadoscliente.cidadeCob = removeAcentos(dadoscli(0)("CLI_CIDADE"))
        dadoscliente.cepCob = dadoscli(0)("CLI_CEP")

        Try
            resposta = gs.cadastro(autenticacao, dadoscliente, idpoli)
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)
        Return arr

    End Function

    Public Function AddTerminal(cnpjcliente As String, idpoli As Integer) As ArrayList
        Dim arr As New ArrayList

        Try
            resposta = gs.addTerminal(autenticacao, cnpjcliente, idpoli)

        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)
        Return arr
    End Function

    Public Function Politicas() As ArrayList
        Dim arr As New ArrayList

        Try
            arr.Add(gs.politicas(autenticacao))
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        Return arr

    End Function

    Public Function Bloqeuar(numterminal As String) As ArrayList
        Dim arr As New ArrayList

        Try
            resposta = gs.bloquear(autenticacao, numterminal)
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)

        Return arr
    End Function
    Public Function AddUsuario(ByVal empresa As DataTable, ByVal usuario As DataTable, cpf As String) As ArrayList
        'Metodo para add usuario nas revendas

        Dim arr As New ArrayList


        dadosusuario.bairro = empresa(0)("EMP_BAIRRO")
        dadosusuario.cep = empresa(0)("EMP_CEP")
        dadosusuario.cidade = empresa(0)("EMP_CIDADE")
        dadosusuario.complemento = "Não Possui"
        dadosusuario.cpf = cpf
        dadosusuario.ddd = empresa(0)("EMP_DDDTELEFONE")
        dadosusuario.ddd2 = empresa(0)("EMP_DDDTELEFONE")
        dadosusuario.email = usuario(0)("USU_EMAIL")
        dadosusuario.logradouro = empresa(0)("EMP_ENDERECO")
        dadosusuario.nome = usuario(0)("USU_NOME")
        dadosusuario.numero = usuario(0)("USU_NUMERO")
        dadosusuario.telefone = empresa(0)("EMP_TELEFONE")
        dadosusuario.telefone2 = empresa(0)("EMP_TELEFONE")
        dadosusuario.uf = empresa(0)("EMP_UF")
        dadosusuario.usuario = empresa(0)("EMP_NOMEFANTASIA")
        dadosusuario.senha = "Elgin_Gsurf"
        Try
            resposta = gs.addUsuario(autenticacao, dadosusuario)
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)
        Return arr
    End Function

    Public Function ConcederPemissao(usuario As String, idpermissao As Integer) As ArrayList
        Dim arr As New ArrayList
        Try
            resposta = gs.concederPermissao(autenticacao, usuario, idpermissao)
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)
        Return arr
    End Function

    Public Function concederPermissoes(usuario As String, idpermissoes() As Integer) As ArrayList
        Dim arr As New ArrayList
        Try
            resposta = gs.concederPermissoes(autenticacao, usuario, idpermissoes)
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)
        Return arr
    End Function

    Public Function Desbloquear(numterminal As String) As ArrayList
        Dim arr As New ArrayList

        Try
            resposta = gs.desbloquear(autenticacao, numterminal)
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)

        Return arr
    End Function
    Public Function Cancelar(numterminal As String) As ArrayList
        Dim arr As New ArrayList

        Try
            resposta = gs.cancelar(autenticacao, numterminal)
        Catch ex As Exception
            Throw New Exception(ex.Message)
        End Try

        arr.Add(resposta.retorno)
        arr.Add(resposta.mensagem)

        Return arr
    End Function
End Class

Public Class Integra_Comnect
    Private FlagProducao As Boolean

    Public Sub New(ByVal Producao As Boolean)
        FlagProducao = Producao
    End Sub

    Public Function Metodo_Revenda(EmpCodigo As Integer, UsuCodigo As Integer) As String
        Try
            Dim selEmpresa As New SelectSP("AC_SP_SEL_EMPRESA")
            selEmpresa.addParam("@EMP_CODIGO", EmpCodigo)
            selEmpresa.Executa()

            Dim selUsuario As New SelectSP("AC_SP_SEL_USUARIOS")
            selUsuario.addParam("@USU_CODIGO", UsuCodigo)
            selUsuario.Executa()

            Dim InscriEstadual As String = ""
            Dim nomeContato As String = ""
            Dim empNumero As String = ""
            Dim Complemento As String = ""
            Dim vlCNPJRevenda As String = ""
            Dim vlCPFResponsavel As String = ""
            Dim vlCPFUser As String = ""
            Dim vlSenha As String
            Dim vlSenhaRandomica As String
            Dim rdn As Random = New Random()
            Dim DDDTelefone As String = ""
            Dim DDDFax As String = ""

            If Not IsDBNull(selEmpresa.sDataTable.Rows(0)("EMP_IE")) Then InscriEstadual = selEmpresa.sDataTable.Rows(0)("EMP_IE")
            If Not IsDBNull(selEmpresa.sDataTable.Rows(0)("EMP_NOMECONTATO")) Then nomeContato = selEmpresa.sDataTable.Rows(0)("EMP_NOMECONTATO")
            If Not IsDBNull(selEmpresa.sDataTable.Rows(0)("EMP_NUMERO")) Then empNumero = selEmpresa.sDataTable.Rows(0)("EMP_NUMERO")
            If Not IsDBNull(selEmpresa.sDataTable.Rows(0)("EMP_COMPLEMENTO")) Then Complemento = selEmpresa.sDataTable.Rows(0)("EMP_COMPLEMENTO")
            If Complemento = "" Then
                Complemento = "-"
            End If
            If nomeContato = "" Then
                If Not IsDBNull(selEmpresa.sDataTable.Rows(0)("EMP_RESPONSAVEL_LEGAL")) Then nomeContato = selEmpresa.sDataTable.Rows(0)("EMP_RESPONSAVEL_LEGAL")
            End If
            If Not IsDBNull(selEmpresa.sDataTable.Rows(0)("EMP_DDDTELEFONE")) Then DDDTelefone = Trim(selEmpresa.sDataTable.Rows(0)("EMP_DDDTELEFONE"))
            If Not IsDBNull(selEmpresa.sDataTable.Rows(0)("EMP_DDDFAX")) Then DDDFax = Trim(selEmpresa.sDataTable.Rows(0)("EMP_DDDFAX"))

            vlCNPJRevenda = Replace(selEmpresa.sDataTable.Rows(0)("EMP_CNPJ"), ".", "")
            vlCNPJRevenda = Replace(vlCNPJRevenda, "/", "")
            vlCNPJRevenda = Replace(vlCNPJRevenda, "-", "")

            'Comentado 2 Linhas Abaixo em 14/07/2014 - Por Claudio Shiniti: Não vai mais entrar na tela para cadastrar o CPF do responsável legal da Revenda, no cadastro inicial, vai passar direto agora, enviado o código da empresa no lugar.
            'vlCPFResponsavel = Replace(selEmpresa.sDataTable.Rows(0)("EMP_CPF_RESPONSAVEL"), ".", "")
            'vlCPFResponsavel = Replace(vlCPFResponsavel, "-", "")
            vlCPFResponsavel = EmpCodigo.ToString()

            vlCPFUser = Replace(selUsuario.sDataTable.Rows(0)("USU_CPF"), ".", "")
            vlCPFUser = Replace(vlCPFUser, "-", "")

            If vlCPFUser = Nothing Then vlCPFUser = "" 'Tratado pois CPF de usuário a maioria vem sem preencher

            vlSenhaRandomica = rdn.Next(1000, 9999).ToString()
            vlSenha = selUsuario.sDataTable.Rows(0)("USU_EMAIL").Trim().ToLower() + "~~~chave_projeto_ac~~~" + vlSenhaRandomica

            Dim CriptoKlarionTech As New Criptografia

            Dim WS_Comnect As Object
            Dim WS_Resposta As Object
            Dim WS_Autenticacao As Object
            Dim WS_DadosCliente As Object
            Dim WS_DadosUsuario As Object
            Dim WS_Politicas As Object
            Dim WS_AddPolitica As Object

            If FlagProducao Then 'Caso for Consumir o WS de Produção da Comnect
                WS_Comnect = New Comnect_Principal.webservice_portClient()
                WS_Resposta = New Comnect_Principal.respostarevenda
                WS_Autenticacao = New Comnect_Principal.webservice_controllerautenticacao
                WS_DadosCliente = New Comnect_Principal.webservice_controllerdadoscliente
                WS_DadosUsuario = New Comnect_Principal.webservice_controllerdadosusuario
                WS_Politicas = New Comnect_Principal.respostapoliticas
                WS_AddPolitica = New Comnect_Principal.respostaaddpoliticarevenda

                WS_Autenticacao.usuario = "Elgin"
                WS_Autenticacao.token = "49550864"
                WS_Autenticacao.wsuser = "elginspws"
            Else 'Caso for Consumir o WS de Homologação da Comnect
                WS_Comnect = New Comnect_Homolog.webservice_portClient()
                WS_Resposta = New Comnect_Homolog.respostarevenda
                WS_Autenticacao = New Comnect_Homolog.webservice_controllerautenticacao
                WS_DadosCliente = New Comnect_Homolog.webservice_controllerdadoscliente
                WS_DadosUsuario = New Comnect_Homolog.webservice_controllerdadosusuario
                WS_Politicas = New Comnect_Homolog.respostapoliticas
                WS_AddPolitica = New Comnect_Homolog.respostaaddpoliticarevenda

                WS_Autenticacao.usuario = "Elgin"
                WS_Autenticacao.token = "49550864"
                WS_Autenticacao.wsuser = "elginspws"
            End If

            WS_DadosCliente.cnpj = vlCNPJRevenda
            WS_DadosCliente.razao = Trim(selEmpresa.sDataTable.Rows(0)("EMP_RAZAOSOCIAL"))
            WS_DadosCliente.fantasia = Trim(selEmpresa.sDataTable.Rows(0)("EMP_NOMEFANTASIA"))
            WS_DadosCliente.inscestadual = Trim(selEmpresa.sDataTable.Rows(0)("EMP_IE"))
            WS_DadosCliente.responsavel = Trim(nomeContato)
            WS_DadosCliente.cpfresponsavel = vlCPFResponsavel
            WS_DadosCliente.contato = Trim(selEmpresa.sDataTable.Rows(0)("EMP_NOMECONTATO"))
            WS_DadosCliente.logradouro = Trim(selEmpresa.sDataTable.Rows(0)("EMP_ENDERECO"))
            WS_DadosCliente.numero = Trim(selEmpresa.sDataTable.Rows(0)("EMP_NUMERO"))
            WS_DadosCliente.bairro = Trim(selEmpresa.sDataTable.Rows(0)("EMP_BAIRRO"))
            WS_DadosCliente.complemento = Trim(selEmpresa.sDataTable.Rows(0)("EMP_COMPLEMENTO"))
            WS_DadosCliente.uf = selEmpresa.sDataTable.Rows(0)("EMP_UF")
            WS_DadosCliente.cidade = Trim(selEmpresa.sDataTable.Rows(0)("EMP_CIDADE"))
            WS_DadosCliente.cep = Trim(selEmpresa.sDataTable.Rows(0)("EMP_CEP"))
            WS_DadosCliente.ddd = DDDTelefone
            WS_DadosCliente.telefone = Trim(selEmpresa.sDataTable.Rows(0)("EMP_TELEFONE"))
            WS_DadosCliente.ddd2 = DDDFax
            WS_DadosCliente.telefone2 = Trim(selEmpresa.sDataTable.Rows(0)("EMP_FAX"))
            WS_DadosCliente.email = Trim(selEmpresa.sDataTable.Rows(0)("EMP_EMAIL"))

            WS_DadosUsuario.cpf = vlCPFUser
            WS_DadosUsuario.nome = Trim(selUsuario.sDataTable.Rows(0)("USU_NOME"))
            WS_DadosUsuario.logradouro = Trim(selUsuario.sDataTable.Rows(0)("USU_ENDERECO"))
            WS_DadosUsuario.numero = Trim(selUsuario.sDataTable.Rows(0)("USU_NUMERO"))
            WS_DadosUsuario.bairro = Trim(selUsuario.sDataTable.Rows(0)("USU_BAIRRO"))
            WS_DadosUsuario.complemento = Trim(selUsuario.sDataTable.Rows(0)("USU_COMPLEMENTO"))
            WS_DadosUsuario.uf = Trim(selUsuario.sDataTable.Rows(0)("USU_UF"))
            WS_DadosUsuario.cidade = Trim(selUsuario.sDataTable.Rows(0)("USU_CIDADE"))
            WS_DadosUsuario.cep = ""
            WS_DadosUsuario.ddd = Trim(selUsuario.sDataTable.Rows(0)("USU_DDDTELEFONE"))
            WS_DadosUsuario.telefone = Trim(selUsuario.sDataTable.Rows(0)("USU_TELEFONE"))
            WS_DadosUsuario.ddd2 = Trim(selUsuario.sDataTable.Rows(0)("USU_DDDCELULAR"))
            WS_DadosUsuario.telefone2 = Trim(selUsuario.sDataTable.Rows(0)("USU_CELULAR"))
            WS_DadosUsuario.email = Trim(selUsuario.sDataTable.Rows(0)("USU_EMAIL"))
            WS_DadosUsuario.usuario = "emp" & EmpCodigo.ToString()
            WS_DadosUsuario.senha = vlSenhaRandomica

            WS_Resposta = WS_Comnect.revenda(WS_Autenticacao, WS_DadosCliente, WS_DadosUsuario)

            If WS_Resposta.retorno = "false" Then
                Return WS_Resposta.mensagem
            Else
                Dim InsEmpIntegrada As New ExecutaSP("AC_SP_INS_EMPRESA_INTEGRADA")
                InsEmpIntegrada.addParam("@EMI_EMPCODIGO", EmpCodigo)
                InsEmpIntegrada.addParam("@EMI_WSECODIGO", 8) '8 = Código do WS da Comnect
                InsEmpIntegrada.addParam("@EMI_USUCODIGO", UsuCodigo)
                InsEmpIntegrada.addParam("@EMI_IP", HttpContext.Current.Request.UserHostAddress)
                InsEmpIntegrada.addParam("@EMI_LOGIN", "emp" & EmpCodigo.ToString())
                InsEmpIntegrada.addParam("@EMI_SENHA", CriptoKlarionTech.Criptografar(vlSenha, "14061910"))

                InsEmpIntegrada.Executa()
                InsEmpIntegrada.Confirma()

                WS_Politicas = WS_Comnect.politicas(WS_Autenticacao)

                If WS_Politicas.retorno = "false" Then
                    Return WS_Politicas.mensagem
                Else
                    Dim dados = Split(WS_Politicas.mensagem, ":")
                    Dim i As Long
                    For i = 0 To UBound(dados) - 1
                        Dim dados2 = Split(dados(i), "|")

                        WS_AddPolitica = WS_Comnect.addpoliticarevenda(WS_Autenticacao, vlCNPJRevenda, dados2(0))

                        If WS_AddPolitica.retorno = "false" Then
                            Return WS_AddPolitica.mensagem
                        End If
                    Next
                End If
            End If
        Catch ex As Exception
            Return ex.Message
        End Try

        Return "OK"
    End Function

    Public Function Metodo_Cadastro(ByVal dadosrevenda As DataTable, ByVal dadoscliente As DataTable, dadosproduto As DataTable, idPolitica As String, numpedido As Integer, idLinha As Integer, idCategoria As Integer, Optional Inserir As ExecutaSP = Nothing, Optional numsp As Integer = 0, Optional multiloja As Integer = 0) As String
        Dim DT_Cli_Atendimento As DataTable

        Dim selEmpIntegrada As New SelectSP("AC_SP_SEL_EMPRESA_INTEGRADA")
        selEmpIntegrada.addParam("@EMI_EMPCODIGO", dadosrevenda.Rows(0)("EMP_CODIGO"))
        selEmpIntegrada.addParam("@EMI_WSECODIGO", 8) 'Código = 8 (WS da Comnect)
        selEmpIntegrada.Executa()

        If selEmpIntegrada.sDataTable.Rows.Count = 0 Then
            Return "Empresa não cadastrada no fornecedor de VPN - Comnect"
        End If

        Dim vlCNPJCliente As String = ""
        Dim CriptoKlarionTech As New Criptografia
        Dim vlArraySenha() As String
        Dim vlSenha As String
        Dim DDDTelefone As String = ""
        Dim DDDFax As String = ""
        Dim IDCustom As Integer

        IDCustom = dadoscliente.Rows(0)("CLI_CODIGO")

        vlSenha = CriptoKlarionTech.Descriptografar(selEmpIntegrada.sDataTable.Rows(0)("EMI_SENHA"), "14061910") 'Chave da Criptografia de senhas da KlarionTech

        vlArraySenha = vlSenha.Split("~")

        vlSenha = vlArraySenha(6)

        vlCNPJCliente = Replace(dadoscliente.Rows(0)("CLI_CNPJ"), ".", "")
        vlCNPJCliente = Replace(vlCNPJCliente, "/", "")
        vlCNPJCliente = Replace(vlCNPJCliente, "-", "")

        'If idPolitica = "34" Then 'Como vem engessado por causa do WS da GSurf, converte aqui para os códigos de política da Comnect (34 na GSurf é DED / Na Comnect o DED é 1)
        '    idPolitica = "1"
        'ElseIf idPolitica = "33" Then '(33 na GSurf é Varejo IP / Na Comnect o Varejo IP é 27)
        '    idPolitica = "27"
        'End If

        'Comentado Bloco Acima em 18/11/2015 - Por Claudio Shiniti: No novo Esquema do WS do Reinaldo (Comnect), o idPolitica será sempre = 119
        If IsDBNull(dadosproduto.Rows(0)("PDT_INTEGRA_COMNECT")) Then 'Caso esse campo for Nulo, pega nas regras abaixo. Caso vier preenchido considera ele - Por Claudio Shiniti em 16/04/2017
            If multiloja = 1 Then 'If Incluído em 13/01/2016 - Por Claudio Shiniti: Conforme combinado com o Reinaldo, para o caso de multiloja, a política é sempre 41
                idPolitica = "41"
            Else
                If idCategoria = 46 Then
                    idPolitica = "80"
                Else
                    idPolitica = "119"
                End If
            End If
        Else
            idPolitica = dadosproduto.Rows(0)("PDT_INTEGRA_COMNECT")
        End If

        If Not IsDBNull(dadoscliente.Rows(0)("CLI_DDDTELEFONE")) Then DDDTelefone = Trim(dadoscliente.Rows(0)("CLI_DDDTELEFONE"))
        If Not IsDBNull(dadoscliente.Rows(0)("CLI_DDDFAX")) Then DDDFax = Trim(dadoscliente.Rows(0)("CLI_DDDFAX"))

        Dim WS_Comnect As Object
        Dim WS_Resposta As Object
        Dim WS_Autenticacao As Object
        Dim WS_DadosCliente As Object
        Dim WS_Resposta_atualizarcliente As Object
        Dim WS_Resposta_add As Object
        Dim WS_Resposta_addcnpjmultiloja As Object

        If FlagProducao Then 'Caso for Consumir o WS de Produção da Comnect
            WS_Comnect = New Comnect_Principal.webservice_portClient()
            WS_Resposta = New Comnect_Principal.respostacadastro
            WS_Autenticacao = New Comnect_Principal.webservice_controllerautenticacao
            WS_DadosCliente = New Comnect_Principal.webservice_controllerdadoscliente
            WS_Resposta_add = New Comnect_Principal.respostaaddterminal
            WS_Resposta_addcnpjmultiloja = New Comnect_Principal.respostaaddcnpjmultiloja
        Else 'Caso for Consumir o WS de Homologação da Comnect
            WS_Comnect = New Comnect_Homolog.webservice_portClient()
            WS_Resposta = New Comnect_Homolog.respostacadastro
            WS_Autenticacao = New Comnect_Homolog.webservice_controllerautenticacao
            WS_DadosCliente = New Comnect_Homolog.webservice_controllerdadoscliente
            WS_Resposta_add = New Comnect_Homolog.respostaaddterminal
            WS_Resposta_addcnpjmultiloja = New Comnect_Homolog.respostaaddcnpjmultiloja
        End If

        WS_Autenticacao.usuario = "Elgin"
        WS_Autenticacao.token = vlSenha
        WS_Autenticacao.wsuser = selEmpIntegrada.sDataTable.Rows(0)("EMI_LOGIN")

        WS_DadosCliente.cnpj = vlCNPJCliente
        WS_DadosCliente.razao = Trim(dadoscliente.Rows(0)("CLI_RAZAO_SOCIAL"))
        WS_DadosCliente.fantasia = Trim(dadoscliente.Rows(0)("CLI_NOME_FANTASIA"))
        WS_DadosCliente.inscestadual = Trim(dadoscliente.Rows(0)("CLI_IE"))
        WS_DadosCliente.responsavel = Trim(dadoscliente.Rows(0)("CLI_NOME_PROPRIETARIO"))
        WS_DadosCliente.cpfresponsavel = ""
        WS_DadosCliente.contato = Trim(dadoscliente.Rows(0)("CLI_CONTATO"))
        WS_DadosCliente.logradouro = Trim(dadoscliente.Rows(0)("CLI_ENDERECO"))
        WS_DadosCliente.numero = Trim(dadoscliente.Rows(0)("CLI_NUMERO"))
        WS_DadosCliente.bairro = Trim(dadoscliente.Rows(0)("CLI_BAIRRO"))
        WS_DadosCliente.complemento = Trim(dadoscliente.Rows(0)("CLI_COMPLEMENTO"))
        WS_DadosCliente.uf = dadoscliente.Rows(0)("CLI_UF")
        WS_DadosCliente.cidade = Trim(dadoscliente.Rows(0)("CLI_CIDADE"))
        WS_DadosCliente.cep = Trim(dadoscliente.Rows(0)("CLI_CEP"))
        WS_DadosCliente.ddd = DDDTelefone
        WS_DadosCliente.telefone = Trim(dadoscliente.Rows(0)("CLI_TELEFONE"))
        WS_DadosCliente.ddd2 = DDDFax
        WS_DadosCliente.telefone2 = Trim(dadoscliente.Rows(0)("CLI_FAX"))
        WS_DadosCliente.email = Trim(dadoscliente.Rows(0)("CLI_EMAIL"))

        DT_Cli_Atendimento = AbreBancoDT("SELECT DATEPART(hh, CLA_HORARIO_INI) AS Hora_Inicio, DATEPART(hh , CLA_HORARIO_FIM) AS Hora_Fim FROM TB_CLI_ATENDIMENTO WHERE CLA_CLICODIGO = " & IDCustom & " AND (CLA_DIA_SEM_INI BETWEEN 2 AND 6 OR CLA_DIA_SEM_FIM BETWEEN 2 AND 6)")

        If DT_Cli_Atendimento.Rows.Count > 0 Then 'Dias Úteis
            If DT_Cli_Atendimento.Rows(0)("Hora_Inicio") = 1 And DT_Cli_Atendimento.Rows(0)("Hora_Fim") = 23 Then 'Caso for 24 Horas
                WS_DadosCliente.seg_sex_open = ""
                WS_DadosCliente.seg_sex_close = ""
                WS_DadosCliente.horario_24_seg_sex = "1"
            Else
                WS_DadosCliente.seg_sex_open = Format(DT_Cli_Atendimento.Rows(0)("Hora_Inicio"), "00").ToString & ":00:00"
                WS_DadosCliente.seg_sex_close = Format(DT_Cli_Atendimento.Rows(0)("Hora_Fim"), "00").ToString & ":00:00"
                WS_DadosCliente.horario_24_seg_sex = "0"
            End If
        Else
            WS_DadosCliente.seg_sex_open = ""
            WS_DadosCliente.seg_sex_close = ""
            WS_DadosCliente.horario_24_seg_sex = ""
        End If

        DT_Cli_Atendimento = AbreBancoDT("SELECT DATEPART(hh, CLA_HORARIO_INI) AS Hora_Inicio, DATEPART(hh , CLA_HORARIO_FIM) AS Hora_Fim FROM TB_CLI_ATENDIMENTO WHERE CLA_CLICODIGO = " & IDCustom & " AND (CLA_DIA_SEM_INI IN (1,7) OR CLA_DIA_SEM_FIM IN (1,7))")

        If DT_Cli_Atendimento.Rows.Count > 0 Then 'Sábados
            If DT_Cli_Atendimento.Rows(0)("Hora_Inicio") = 1 And DT_Cli_Atendimento.Rows(0)("Hora_Fim") = 23 Then 'Caso for 24 Horas
                WS_DadosCliente.sab_open = ""
                WS_DadosCliente.sab_close = ""
                WS_DadosCliente.horario_24_sab = "1"
            Else
                WS_DadosCliente.sab_open = Format(DT_Cli_Atendimento.Rows(0)("Hora_Inicio"), "00").ToString & ":00:00"
                WS_DadosCliente.sab_close = Format(DT_Cli_Atendimento.Rows(0)("Hora_Fim"), "00").ToString & ":00:00"
                WS_DadosCliente.horario_24_sab = "0"
            End If
        Else
            WS_DadosCliente.sab_open = ""
            WS_DadosCliente.sab_close = ""
            WS_DadosCliente.horario_24_sab = ""
        End If

        DT_Cli_Atendimento = AbreBancoDT("SELECT DATEPART(hh, CLA_HORARIO_INI) AS Hora_Inicio, DATEPART(hh , CLA_HORARIO_FIM) AS Hora_Fim FROM TB_CLI_ATENDIMENTO WHERE CLA_CLICODIGO = " & IDCustom & " AND (CLA_DIA_SEM_INI = 1 OR CLA_DIA_SEM_FIM = 1)")

        If DT_Cli_Atendimento.Rows.Count > 0 Then 'Domingos
            If DT_Cli_Atendimento.Rows(0)("Hora_Inicio") = 1 And DT_Cli_Atendimento.Rows(0)("Hora_Fim") = 23 Then 'Caso for 24 Horas
                WS_DadosCliente.dom_open = ""
                WS_DadosCliente.dom_close = ""
                WS_DadosCliente.horario_24_dom = "1"
            Else
                WS_DadosCliente.dom_open = Format(DT_Cli_Atendimento.Rows(0)("Hora_Inicio"), "00").ToString & ":00:00"
                WS_DadosCliente.dom_close = Format(DT_Cli_Atendimento.Rows(0)("Hora_Fim"), "00").ToString & ":00:00"
                WS_DadosCliente.horario_24_dom = "0"
            End If
        Else
            WS_DadosCliente.dom_open = ""
            WS_DadosCliente.dom_close = ""
            WS_DadosCliente.horario_24_dom = ""
        End If

        WS_Resposta = WS_Comnect.cadastro(WS_Autenticacao, WS_DadosCliente, idPolitica, IDCustom)

        If WS_Resposta.retorno = "false" Then
            If WS_Resposta.mensagem.IndexOf("Ja existe um cliente cadastrado com o cnpj informado") <> -1 Then 'Caso a mensagem retornada for que o cliente já existe, consome apenas o método addterminal
                WS_Resposta_atualizarcliente = WS_Comnect.atualizarcliente(WS_Autenticacao, WS_DadosCliente) 'Atualiza os dados do Cliente no WS da Comnect

                If WS_Resposta_atualizarcliente.retorno = "false" Then
                    Return WS_Resposta_atualizarcliente.mensagem
                End If

                WS_Resposta_add = WS_Comnect.addterminal(WS_Autenticacao, vlCNPJCliente, idPolitica)

                If WS_Resposta_add.retorno = "false" Then
                    Return WS_Resposta_add.mensagem
                Else
                    Inserir.AddSP("AC_SP_INS_TERMINAIS_VPN")
                    Dim CodTerminal() As String = Split(WS_Resposta_add.mensagem, "|")

                    Inserir.addParam("@TVN_CLICODIGO", dadoscliente.Rows(0)("CLI_CODIGO"), numsp)
                    Inserir.addParam("@TVN_CONTA", CodTerminal(0), numsp)
                    Inserir.addParam("@TVN_PEDIDO", numpedido, numsp)
                    Inserir.addParam("@TVN_LINCODIGO", idLinha, numsp)
                    Inserir.addParam("@TVN_WSECODIGO", 8, numsp) '8 = Código do WS da Comnect
                    Inserir.addParam("@TVN_USUARIO_VPN", CodTerminal(0), numsp) 'Incluído em 22/07/2015 - Por Claudio Shiniti: Novo esquema do WS do Reinaldo que já devolve usúario e senha da VPN, e já ativa o terminal instantaneamente
                    Inserir.addParam("@TVN_SENHA_VPN", CodTerminal(1), numsp) 'Incluído em 22/07/2015 - Por Claudio Shiniti: Novo esquema do WS do Reinaldo que já devolve usúario e senha da VPN, e já ativa o terminal instantaneamente
                    Inserir.addParam("@TVN_LINK_DOWNLOAD", CodTerminal(3), numsp) 'Fixo para todos os casos a partir de agora

                    Inserir.Executa(numsp)

                    If multiloja = 1 Then 'Caso for Pedido MultiLoja, envia para o WS da Comnect o CNPJ de todas as filiais existentes nesse pedido
                        Dim vlCNPJ_Filial As String
                        Dim SelFiliais As New SelectSP("AC_SP_SEL_FILIAL_DEDICADO_MULTILOJA", Inserir.Conexao, Inserir.Transacao)

                        SelFiliais.addParam("@PDM_DEDCODIGO", numpedido)

                        SelFiliais.Executa()

                        If SelFiliais.sDataTable.Rows.Count > 0 Then
                            For K = 0 To SelFiliais.sDataTable.Rows.Count - 1
                                vlCNPJ_Filial = SelFiliais.sDataTable.Rows(K)("CLI_CNPJ").replace(".", "")
                                vlCNPJ_Filial = vlCNPJ_Filial.Replace("/", "")
                                vlCNPJ_Filial = vlCNPJ_Filial.Replace("-", "")

                                WS_Resposta_addcnpjmultiloja = WS_Comnect.addcnpjmultiloja(WS_Autenticacao, CodTerminal(0), vlCNPJ_Filial)

                                If WS_Resposta_addcnpjmultiloja.retorno = "false" Then
                                    Return WS_Resposta_addcnpjmultiloja.mensagem
                                End If
                            Next
                        End If
                    End If

                    'Caso Identificar que o Produto Requer 1 VPN por Caixa, adiciona o restante abaixo, caso houver mais de 1 PDV no pedido
                    If dadosproduto.Rows(0)("PDT_VPN_POR_PDV") Then
                        Dim SelPedido As New SelectSP("AC_SP_SEL_PEDIDOS_DEDICADO", Inserir.Conexao, Inserir.Transacao)

                        SelPedido.addParam("@DED_CODIGO", numpedido)

                        SelPedido.Executa()

                        For K = 1 To SelPedido.sDataTable.Rows(0)("DED_QTDE_PDV") - 1
                            WS_Resposta_add = WS_Comnect.addterminal(WS_Autenticacao, vlCNPJCliente, idPolitica)

                            If WS_Resposta_add.retorno = "false" Then
                                Return WS_Resposta_add.mensagem
                            Else
                                CodTerminal = Split(WS_Resposta_add.mensagem, "|")

                                Inserir.Comando(numsp).Parameters.Clear()
                                Inserir.addParam("@TVN_CLICODIGO", dadoscliente.Rows(0)("CLI_CODIGO"), numsp)
                                Inserir.addParam("@TVN_CONTA", CodTerminal(0), numsp)
                                Inserir.addParam("@TVN_PEDIDO", numpedido, numsp)
                                Inserir.addParam("@TVN_LINCODIGO", idLinha, numsp)
                                Inserir.addParam("@TVN_WSECODIGO", 8, numsp) '8 = Código do WS da Comnect
                                Inserir.addParam("@TVN_USUARIO_VPN", CodTerminal(0), numsp) 'Incluído em 22/07/2015 - Por Claudio Shiniti: Novo esquema do WS do Reinaldo que já devolve usúario e senha da VPN, e já ativa o terminal instantaneamente
                                Inserir.addParam("@TVN_SENHA_VPN", CodTerminal(1), numsp) 'Incluído em 22/07/2015 - Por Claudio Shiniti: Novo esquema do WS do Reinaldo que já devolve usúario e senha da VPN, e já ativa o terminal instantaneamente
                                Inserir.addParam("@TVN_LINK_DOWNLOAD", CodTerminal(3), numsp) 'Fixo para todos os casos a partir de agora

                                Inserir.Executa(numsp)
                            End If
                        Next
                    End If
                    '-----------------------------------------------------------------------------------------------------------------------

                    Return "OK"
                End If
            End If

            Return WS_Resposta.mensagem
        Else
            Inserir.AddSP("AC_SP_INS_TERMINAIS_VPN")
            Dim CodTerminal() As String = Split(WS_Resposta.mensagem, "|")

            Inserir.addParam("@TVN_CLICODIGO", dadoscliente.Rows(0)("CLI_CODIGO"), numsp)
            Inserir.addParam("@TVN_CONTA", CodTerminal(0), numsp)
            Inserir.addParam("@TVN_PEDIDO", numpedido, numsp)
            Inserir.addParam("@TVN_LINCODIGO", idLinha, numsp)
            Inserir.addParam("@TVN_WSECODIGO", 8, numsp) '8 = Código do WS da Comnect
            Inserir.addParam("@TVN_USUARIO_VPN", CodTerminal(0), numsp) 'Incluído em 22/07/2015 - Por Claudio Shiniti: Novo esquema do WS do Reinaldo que já devolve usúario e senha da VPN, e já ativa o terminal instantaneamente
            Inserir.addParam("@TVN_SENHA_VPN", CodTerminal(1), numsp) 'Incluído em 22/07/2015 - Por Claudio Shiniti: Novo esquema do WS do Reinaldo que já devolve usúario e senha da VPN, e já ativa o terminal instantaneamente
            Inserir.addParam("@TVN_LINK_DOWNLOAD", CodTerminal(3), numsp) 'Fixo para todos os casos a partir de agora

            Inserir.Executa(numsp)

            If multiloja = 1 Then 'Caso for Pedido MultiLoja, envia para o WS da Comnect o CNPJ de todas as filiais existentes nesse pedido
                Dim vlCNPJ_Filial As String
                Dim SelFiliais As New SelectSP("AC_SP_SEL_FILIAL_DEDICADO_MULTILOJA", Inserir.Conexao, Inserir.Transacao)

                SelFiliais.addParam("@PDM_DEDCODIGO", numpedido)

                SelFiliais.Executa()

                If SelFiliais.sDataTable.Rows.Count > 0 Then
                    For K = 0 To SelFiliais.sDataTable.Rows.Count - 1
                        vlCNPJ_Filial = SelFiliais.sDataTable.Rows(K)("CLI_CNPJ").replace(".", "")
                        vlCNPJ_Filial = vlCNPJ_Filial.Replace("/", "")
                        vlCNPJ_Filial = vlCNPJ_Filial.Replace("-", "")

                        WS_Resposta_addcnpjmultiloja = WS_Comnect.addcnpjmultiloja(WS_Autenticacao, CodTerminal(0), vlCNPJ_Filial)

                        If WS_Resposta_addcnpjmultiloja.retorno = "false" Then
                            Return WS_Resposta_addcnpjmultiloja.mensagem
                        End If
                    Next
                End If
            End If

            'Caso Identificar que o Produto Requer 1 VPN por Caixa, adiciona o restante abaixo, caso houver mais de 1 PDV no pedido
            If dadosproduto.Rows(0)("PDT_VPN_POR_PDV") Then
                Dim SelPedido As New SelectSP("AC_SP_SEL_PEDIDOS_DEDICADO", Inserir.Conexao, Inserir.Transacao)

                SelPedido.addParam("@DED_CODIGO", numpedido)

                SelPedido.Executa()

                For K = 1 To SelPedido.sDataTable.Rows(0)("DED_QTDE_PDV") - 1
                    WS_Resposta_add = WS_Comnect.addterminal(WS_Autenticacao, vlCNPJCliente, idPolitica)

                    If WS_Resposta_add.retorno = "false" Then
                        Return WS_Resposta_add.mensagem
                    Else
                        CodTerminal = Split(WS_Resposta_add.mensagem, "|")

                        Inserir.Comando(numsp).Parameters.Clear()
                        Inserir.addParam("@TVN_CLICODIGO", dadoscliente.Rows(0)("CLI_CODIGO"), numsp)
                        Inserir.addParam("@TVN_CONTA", CodTerminal(0), numsp)
                        Inserir.addParam("@TVN_PEDIDO", numpedido, numsp)
                        Inserir.addParam("@TVN_LINCODIGO", idLinha, numsp)
                        Inserir.addParam("@TVN_WSECODIGO", 8, numsp) '8 = Código do WS da Comnect
                        Inserir.addParam("@TVN_USUARIO_VPN", CodTerminal(0), numsp) 'Incluído em 22/07/2015 - Por Claudio Shiniti: Novo esquema do WS do Reinaldo que já devolve usúario e senha da VPN, e já ativa o terminal instantaneamente
                        Inserir.addParam("@TVN_SENHA_VPN", CodTerminal(1), numsp) 'Incluído em 22/07/2015 - Por Claudio Shiniti: Novo esquema do WS do Reinaldo que já devolve usúario e senha da VPN, e já ativa o terminal instantaneamente
                        Inserir.addParam("@TVN_LINK_DOWNLOAD", CodTerminal(3), numsp) 'Fixo para todos os casos a partir de agora

                        Inserir.Executa(numsp)
                    End If
                Next
            End If
            '-----------------------------------------------------------------------------------------------------------------------

        End If

        Return "OK"
    End Function

    Public Function Metodo_Altera_Situacao_Terminal(ByVal dadosrevenda As DataTable, ByVal dadoscliente As DataTable, dadosproduto As DataTable, numpedido As Integer, idLinha As Integer, Tipo As Integer) As String
        Dim selEmpIntegrada As New SelectSP("AC_SP_SEL_EMPRESA_INTEGRADA")
        selEmpIntegrada.addParam("@EMI_EMPCODIGO", dadosrevenda.Rows(0)("EMP_CODIGO"))
        selEmpIntegrada.addParam("@EMI_WSECODIGO", 8) 'Código = 8 (WS da Comnect)
        selEmpIntegrada.Executa()

        If selEmpIntegrada.sDataTable.Rows.Count = 0 Then
            Return "Empresa não cadastrada no fornecedor de VPN - Comnect"
        End If

        Dim selTVN As New SelectSP("AC_SP_SEL_TERMINAIS_VPN")
        selTVN.addParam("@TVN_CLICODIGO", dadoscliente.Rows(0)("CLI_CODIGO"))
        selTVN.addParam("@TVN_PEDIDO", numpedido)
        selTVN.addParam("@TVN_LINCODIGO", idLinha)
        selTVN.addParam("@TVN_WSECODIGO", 8) 'Somente Terminais Comnect WNB
        selTVN.Executa()

        If selTVN.sDataTable.Rows.Count = 0 Then
            Return "Código do Terminal de VPN - Comnect não localizado no sistema"
        End If

        Dim CriptoKlarionTech As New Criptografia
        Dim vlArraySenha() As String
        Dim vlSenha As String
        Dim Situacao As Integer

        vlSenha = CriptoKlarionTech.Descriptografar(selEmpIntegrada.sDataTable.Rows(0)("EMI_SENHA"), "14061910") 'Chave da Criptografia de senhas da KlarionTech

        vlArraySenha = vlSenha.Split("~")

        vlSenha = vlArraySenha(6)

        If Tipo = 0 Then 'Cancelar VPN
            'Tipo = 4 '(Mudou os códigos internos de situação, pois foi criado nova AC_SP_UPD_MANIPULA_TERMINAL_VPN) para poder deixar os status de Aguardando
            Tipo = 5 'Por Claudio Shiniti em 28/07/2015 - Passou a ser 5, porque o WS da Comenct vai passar a cancelar Instantaneamente
            Situacao = 3 '(3 = Código Interno do WS da Comnect para Cancelar Terminal VPN)
        ElseIf Tipo = 2 Then 'Bloquear VPN
            'Tipo = 0 '(Mudou os códigos internos de situação, pois foi criado nova AC_SP_UPD_MANIPULA_TERMINAL_VPN) para poder deixar os status de Aguardando
            Tipo = 1 'Por Claudio Shiniti em 29/07/2015 - Passou a ser 1, porque o WS da Comenct vai passar a bloquear Instantaneamente
            Situacao = 4 '(4 = Código Interno do WS da Comnect para Bloquear Terminal VPN)
        ElseIf Tipo = 3 Then 'DesBloquear VPN
            If IsDBNull(dadosproduto.Rows(0)("PDT_INTEGRA_COMNECT")) Then 'Caso esse Campo não for Nulo, é porque tem ID Amarrado no WS da Comnect (EX: TLS). Caso for Nulo, considera o Tipo = 2 (Aguarda Desbloqueio)
                Tipo = 2 '(Mudou os códigos internos de situação, pois foi criado nova AC_SP_UPD_MANIPULA_TERMINAL_VPN) para poder deixar os status de Aguardando
            Else
                If dadosproduto.Rows(0)("PDT_INTEGRA_COMNECT") = 89 Then 'Caso for TLS = 89, já desbloqueia instantaneamente
                    Tipo = 3
                Else
                    Tipo = 2
                End If
            End If
            Situacao = 2 '(2 = Código Interno do WS da Comnect para Ativar Terminal VPN)
        End If

        Dim WS_Comnect As Object
        Dim WS_Resposta As Object
        Dim WS_Autenticacao As Object

        If FlagProducao Then 'Caso for Consumir o WS de Produção da Comnect
            WS_Comnect = New Comnect_Principal.webservice_portClient()
            WS_Resposta = New Comnect_Principal.respostaalterasituacaoterminal
            WS_Autenticacao = New Comnect_Principal.webservice_controllerautenticacao
        Else 'Caso for Consumir o WS de Homologação da Comnect
            WS_Comnect = New Comnect_Homolog.webservice_portClient()
            WS_Resposta = New Comnect_Homolog.respostaalterasituacaoterminal
            WS_Autenticacao = New Comnect_Homolog.webservice_controllerautenticacao
        End If

        WS_Autenticacao.usuario = "Elgin"
        WS_Autenticacao.token = vlSenha
        WS_Autenticacao.wsuser = selEmpIntegrada.sDataTable.Rows(0)("EMI_LOGIN")

        For K = 0 To selTVN.sDataTable.Rows.Count - 1
            WS_Resposta = WS_Comnect.alterasituacaoterminal(WS_Autenticacao, selTVN.sDataTable.Rows(K)("TVN_CONTA"), Situacao)

            If WS_Resposta.retorno = "false" Then
                Return WS_Resposta.mensagem
            Else
                Dim UPD_TVN As New ExecutaSP("AC_SP_UPD_MANIPULA_TERMINAL_VPN")

                UPD_TVN.addParam("@TVN_CONTA", selTVN.sDataTable.Rows(K)("TVN_CONTA"))
                UPD_TVN.addParam("@STATUS", Tipo)

                UPD_TVN.Executa()
                UPD_TVN.Confirma()
            End If
        Next

        Return "OK"
    End Function

    Public Function Metodo_Altera_Senha_Terminal(ByVal idTerminal As Integer, numpedido As Integer, idLinha As Integer, idCliente As Integer) As String
        Dim CodEmpresa As Integer

        If idLinha = 14 Then 'Caso for Pedido Dedicado
            Dim SelPedido As New SelectSP("AC_SP_SEL_PEDIDOS_DEDICADO")

            SelPedido.addParam("@DED_CODIGO", numpedido)

            SelPedido.Executa()

            CodEmpresa = SelPedido.sDataTable.Rows(0)("DED_EMPCODIGO")
        ElseIf idLinha = 18 Then 'Caso for Pedido Varejo
            Dim SelPedido As New SelectSP("AC_SP_SEL_PEDIDOS")

            SelPedido.addParam("@CODIGO", numpedido)
            SelPedido.addParam("@LIN_CODIGO", 18)

            SelPedido.Executa()

            CodEmpresa = SelPedido.sDataTable.Rows(0)("PED_EMPCODIGO")
        End If

        Dim selEmpIntegrada As New SelectSP("AC_SP_SEL_EMPRESA_INTEGRADA")
        selEmpIntegrada.addParam("@EMI_EMPCODIGO", CodEmpresa)
        selEmpIntegrada.addParam("@EMI_WSECODIGO", 8) 'Código = 8 (WS da Comnect)
        selEmpIntegrada.Executa()

        If selEmpIntegrada.sDataTable.Rows.Count = 0 Then
            Return "Empresa não cadastrada no fornecedor de VPN - Comnect"
        End If

        Dim selTVN As New SelectSP("AC_SP_SEL_TERMINAIS_VPN")
        selTVN.addParam("@TVN_CLICODIGO", idCliente)
        selTVN.addParam("@TVN_PEDIDO", numpedido)
        selTVN.addParam("@TVN_LINCODIGO", idLinha)
        selTVN.Executa()

        If selTVN.sDataTable.Rows.Count = 0 Then
            Return "Código do Terminal de VPN - Comnect não localizado no sistema"
        End If

        Dim CriptoKlarionTech As New Criptografia
        Dim vlArraySenha() As String
        Dim vlSenha As String

        vlSenha = CriptoKlarionTech.Descriptografar(selEmpIntegrada.sDataTable.Rows(0)("EMI_SENHA"), "14061910") 'Chave da Criptografia de senhas da KlarionTech

        vlArraySenha = vlSenha.Split("~")

        vlSenha = vlArraySenha(6)

        Dim WS_Comnect As Object
        Dim WS_Resposta As Object
        Dim WS_Autenticacao As Object

        If FlagProducao Then 'Caso for Consumir o WS de Produção da Comnect
            WS_Comnect = New Comnect_Principal.webservice_portClient()
            WS_Resposta = New Comnect_Principal.respostaalterasituacaoterminal
            WS_Autenticacao = New Comnect_Principal.webservice_controllerautenticacao
        Else 'Caso for Consumir o WS de Homologação da Comnect
            WS_Comnect = New Comnect_Homolog.webservice_portClient()
            WS_Resposta = New Comnect_Homolog.respostaalterasituacaoterminal
            WS_Autenticacao = New Comnect_Homolog.webservice_controllerautenticacao
        End If

        WS_Autenticacao.usuario = "Elgin"
        WS_Autenticacao.token = vlSenha
        WS_Autenticacao.wsuser = selEmpIntegrada.sDataTable.Rows(0)("EMI_LOGIN")

        WS_Resposta = WS_Comnect.alterasenhaterminal(WS_Autenticacao, idTerminal, idCliente)

        If WS_Resposta.retorno = "false" Then
            Return WS_Resposta.mensagem
        Else
            Dim UPD_TVN As New ExecutaSP("AC_SP_UPD_SENHA_TERMINAL_VPN")
            Dim CodTerminal() As String = Split(WS_Resposta.mensagem, "|")

            UPD_TVN.addParam("@TVN_CONTA", selTVN.sDataTable.Rows(0)("TVN_CONTA"))
            UPD_TVN.addParam("@TVN_WSECODIGO", selTVN.sDataTable.Rows(0)("TVN_WSECODIGO"))
            UPD_TVN.addParam("@TVN_SENHA_VPN", CodTerminal(1))

            UPD_TVN.Executa()
            UPD_TVN.Confirma()
        End If

        Return "OK"
    End Function

    Public Function AddCNPJMultiLoja(ByVal dadosrevenda As DataTable, ByVal dadoscliente As DataTable, numpedido As Integer, idLinha As Integer, Optional Inserir As ExecutaSP = Nothing, Optional numsp As Integer = 0) As String
        Dim selEmpIntegrada As New SelectSP("AC_SP_SEL_EMPRESA_INTEGRADA")
        selEmpIntegrada.addParam("@EMI_EMPCODIGO", dadosrevenda.Rows(0)("EMP_CODIGO"))
        selEmpIntegrada.addParam("@EMI_WSECODIGO", 8) 'Código = 8 (WS da Comnect)
        selEmpIntegrada.Executa()

        If selEmpIntegrada.sDataTable.Rows.Count = 0 Then
            Return "Empresa não cadastrada no fornecedor de VPN - Comnect"
        End If

        Dim SelTerminaisVPN As New SelectSP("AC_SP_SEL_TERMINAIS_VPN")
        SelTerminaisVPN.addParam("@TVN_CLICODIGO", dadoscliente.Rows(0)("CLI_CODIGO"))
        SelTerminaisVPN.addParam("@TVN_PEDIDO", numpedido)
        SelTerminaisVPN.addParam("@TVN_LINCODIGO", idLinha)
        SelTerminaisVPN.Executa()

        If SelTerminaisVPN.sDataTable.Rows.Count = 0 Then
            Return "Terminal de VPN da Matriz não localizada no sistema"
        End If

        Dim vlCNPJFilial As String = ""
        Dim CriptoKlarionTech As New Criptografia
        Dim vlArraySenha() As String
        Dim vlSenha As String

        vlSenha = CriptoKlarionTech.Descriptografar(selEmpIntegrada.sDataTable.Rows(0)("EMI_SENHA"), "14061910") 'Chave da Criptografia de senhas da KlarionTech

        vlArraySenha = vlSenha.Split("~")

        vlSenha = vlArraySenha(6)

        Dim WS_Comnect As Object
        Dim WS_Autenticacao As Object
        Dim WS_Resposta_addcnpjmultiloja As Object

        If FlagProducao Then 'Caso for Consumir o WS de Produção da Comnect
            WS_Comnect = New Comnect_Principal.webservice_portClient()
            WS_Autenticacao = New Comnect_Principal.webservice_controllerautenticacao
            WS_Resposta_addcnpjmultiloja = New Comnect_Principal.respostaaddcnpjmultiloja
        Else 'Caso for Consumir o WS de Homologação da Comnect
            WS_Comnect = New Comnect_Homolog.webservice_portClient()
            WS_Autenticacao = New Comnect_Homolog.webservice_controllerautenticacao
            WS_Resposta_addcnpjmultiloja = New Comnect_Homolog.respostaaddcnpjmultiloja
        End If

        WS_Autenticacao.usuario = "Elgin"
        WS_Autenticacao.token = vlSenha
        WS_Autenticacao.wsuser = selEmpIntegrada.sDataTable.Rows(0)("EMI_LOGIN")

        Dim dtFiliais As DataTable

        dtFiliais = HttpContext.Current.Session("vg_tabelaFiliaisConsulta")

        For X = 0 To dtFiliais.Rows.Count - 1
            vlCNPJFilial = Replace(dtFiliais.Rows(X)("CLI_CNPJ"), ".", "")
            vlCNPJFilial = Replace(vlCNPJFilial, "/", "")
            vlCNPJFilial = Replace(vlCNPJFilial, "-", "")

            WS_Resposta_addcnpjmultiloja = WS_Comnect.addcnpjmultiloja(WS_Autenticacao, SelTerminaisVPN.sDataTable.Rows(0)("TVN_CONTA"), vlCNPJFilial)

            If WS_Resposta_addcnpjmultiloja.retorno = "false" Then
                Return WS_Resposta_addcnpjmultiloja.mensagem
            End If
        Next

        Return "OK"
    End Function

    Public Function RemoverCNPJMultiLoja(ByVal dadosrevenda As DataTable, ByVal dadoscliente As DataTable, numpedido As Integer, idLinha As Integer, Optional Inserir As ExecutaSP = Nothing, Optional numsp As Integer = 0) As String
        Dim selEmpIntegrada As New SelectSP("AC_SP_SEL_EMPRESA_INTEGRADA")
        selEmpIntegrada.addParam("@EMI_EMPCODIGO", dadosrevenda.Rows(0)("EMP_CODIGO"))
        selEmpIntegrada.addParam("@EMI_WSECODIGO", 8) 'Código = 8 (WS da Comnect)
        selEmpIntegrada.Executa()

        If selEmpIntegrada.sDataTable.Rows.Count = 0 Then
            Return "Empresa não cadastrada no fornecedor de VPN - Comnect"
        End If

        Dim SelTerminaisVPN As New SelectSP("AC_SP_SEL_TERMINAIS_VPN")
        SelTerminaisVPN.addParam("@TVN_CLICODIGO", dadoscliente.Rows(0)("CLI_CODIGO"))
        SelTerminaisVPN.addParam("@TVN_PEDIDO", numpedido)
        SelTerminaisVPN.addParam("@TVN_LINCODIGO", idLinha)
        SelTerminaisVPN.Executa()

        If SelTerminaisVPN.sDataTable.Rows.Count = 0 Then
            Return "Terminal de VPN da Matriz não localizada no sistema"
        End If

        Dim vlCNPJFilial As String = ""
        Dim CriptoKlarionTech As New Criptografia
        Dim vlArraySenha() As String
        Dim vlSenha As String

        vlSenha = CriptoKlarionTech.Descriptografar(selEmpIntegrada.sDataTable.Rows(0)("EMI_SENHA"), "14061910") 'Chave da Criptografia de senhas da KlarionTech

        vlArraySenha = vlSenha.Split("~")

        vlSenha = vlArraySenha(6)

        Dim WS_Comnect As Object
        Dim WS_Autenticacao As Object
        Dim WS_Resposta_removercnpjmultiloja As Object

        If FlagProducao Then 'Caso for Consumir o WS de Produção da Comnect
            WS_Comnect = New Comnect_Principal.webservice_portClient()
            WS_Autenticacao = New Comnect_Principal.webservice_controllerautenticacao
            WS_Resposta_removercnpjmultiloja = New Comnect_Principal.respostaremovercnpjmultiloja
        Else 'Caso for Consumir o WS de Homologação da Comnect
            WS_Comnect = New Comnect_Homolog.webservice_portClient()
            WS_Autenticacao = New Comnect_Homolog.webservice_controllerautenticacao
            WS_Resposta_removercnpjmultiloja = New Comnect_Homolog.respostaremovercnpjmultiloja
        End If

        WS_Autenticacao.usuario = "Elgin"
        WS_Autenticacao.token = vlSenha
        WS_Autenticacao.wsuser = selEmpIntegrada.sDataTable.Rows(0)("EMI_LOGIN")

        Dim Remover As String = HttpContext.Current.Session("vl_CliCodigoMLJ")
        Dim Codigos As String() = Remover.Split(",")

        For X = 0 To Codigos.Length - 1
            If Codigos(X) <> "" Then
                Dim SelCli As New SelectSP("AC_SP_SEL_CLIENTES")
                SelCli.addParam("@CLI_CODIGO", Codigos(X))
                SelCli.Executa()

                vlCNPJFilial = Replace(SelCli.sDataTable.Rows(0)("CLI_CNPJ"), ".", "")
                vlCNPJFilial = Replace(vlCNPJFilial, "/", "")
                vlCNPJFilial = Replace(vlCNPJFilial, "-", "")

                WS_Resposta_removercnpjmultiloja = WS_Comnect.removercnpjmultiloja(WS_Autenticacao, SelTerminaisVPN.sDataTable.Rows(0)("TVN_CONTA"), vlCNPJFilial)

                If WS_Resposta_removercnpjmultiloja.retorno = "false" Then
                    Return WS_Resposta_removercnpjmultiloja.mensagem
                End If
            End If
        Next

        Return "OK"
    End Function

    Public Function TrafegoVPN(ByVal Emp_Codigo As Integer, ByVal Terminais As String) As String
        Dim selEmpIntegrada As New SelectSP("AC_SP_SEL_EMPRESA_INTEGRADA")
        selEmpIntegrada.addParam("@EMI_EMPCODIGO", Emp_Codigo)
        selEmpIntegrada.addParam("@EMI_WSECODIGO", 8) 'Código = 8 (WS da Comnect)
        selEmpIntegrada.Executa()

        If selEmpIntegrada.sDataTable.Rows.Count = 0 Then
            Return "Empresa não cadastrada no fornecedor de VPN - Comnect"
        End If

        Dim CriptoKlarionTech As New Criptografia
        Dim vlArraySenha() As String
        Dim vlSenha As String

        vlSenha = CriptoKlarionTech.Descriptografar(selEmpIntegrada.sDataTable.Rows(0)("EMI_SENHA"), "14061910") 'Chave da Criptografia de senhas da KlarionTech

        vlArraySenha = vlSenha.Split("~")

        vlSenha = vlArraySenha(6)

        Dim WS_Comnect As Object
        Dim WS_Autenticacao As Object
        Dim WS_Resposta_statusvpn As Object

        If FlagProducao Then 'Caso for Consumir o WS de Produção da Comnect
            WS_Comnect = New Comnect_Principal.webservice_portClient()
            WS_Autenticacao = New Comnect_Principal.webservice_controllerautenticacao
            WS_Resposta_statusvpn = New Comnect_Principal.respostastatusvpn
        Else 'Caso for Consumir o WS de Homologação da Comnect
            WS_Comnect = New Comnect_Homolog.webservice_portClient()
            WS_Autenticacao = New Comnect_Homolog.webservice_controllerautenticacao
            WS_Resposta_statusvpn = New Comnect_Homolog.respostastatusvpn
        End If

        WS_Autenticacao.usuario = "Elgin"
        WS_Autenticacao.token = vlSenha
        WS_Autenticacao.wsuser = selEmpIntegrada.sDataTable.Rows(0)("EMI_LOGIN")

        Try
            WS_Resposta_statusvpn = WS_Comnect.statusvpn(WS_Autenticacao, Terminais)
        Catch ex As Exception
            Return "Erro no WebService Comnect - " & ex.Message
        End Try

        If WS_Resposta_statusvpn.retorno = "false" Then
            Return WS_Resposta_statusvpn.mensagem
        End If

        HttpContext.Current.Session("vg_trafego_vpn_comnect") = WS_Resposta_statusvpn.mensagem

        Return "OK"
    End Function

    Public Function GeraTokenAcesso(ByVal Emp_Codigo As Integer) As String
        Dim selEmpIntegrada As New SelectSP("AC_SP_SEL_EMPRESA_INTEGRADA")
        selEmpIntegrada.addParam("@EMI_EMPCODIGO", Emp_Codigo)
        selEmpIntegrada.addParam("@EMI_WSECODIGO", 8) 'Código = 8 (WS da Comnect)
        selEmpIntegrada.Executa()

        If selEmpIntegrada.sDataTable.Rows.Count = 0 Then
            Return "Empresa não cadastrada no fornecedor de VPN - Comnect"
        End If

        Dim CriptoKlarionTech As New Criptografia
        Dim vlArraySenha() As String
        Dim vlSenha As String

        vlSenha = CriptoKlarionTech.Descriptografar(selEmpIntegrada.sDataTable.Rows(0)("EMI_SENHA"), "14061910") 'Chave da Criptografia de senhas da KlarionTech

        vlArraySenha = vlSenha.Split("~")

        vlSenha = vlArraySenha(6)

        Dim WS_Comnect As Object
        Dim WS_Autenticacao As Object
        Dim WS_Resposta_geratokenacesso As Object

        If FlagProducao Then 'Caso for Consumir o WS de Produção da Comnect
            WS_Comnect = New Comnect_Principal.webservice_portClient()
            WS_Autenticacao = New Comnect_Principal.webservice_controllerautenticacao
            WS_Resposta_geratokenacesso = New Comnect_Principal.respostageratokenacesso
        Else 'Caso for Consumir o WS de Homologação da Comnect
            WS_Comnect = New Comnect_Homolog.webservice_portClient()
            WS_Autenticacao = New Comnect_Homolog.webservice_controllerautenticacao
            WS_Resposta_geratokenacesso = New Comnect_Homolog.respostageratokenacesso
        End If

        WS_Autenticacao.usuario = "Elgin"
        WS_Autenticacao.token = vlSenha
        WS_Autenticacao.wsuser = selEmpIntegrada.sDataTable.Rows(0)("EMI_LOGIN")

        Try
            WS_Resposta_geratokenacesso = WS_Comnect.geratokenacesso(WS_Autenticacao)
        Catch ex As Exception
            Return "Erro no WebService Comnect - " & ex.Message
        End Try

        If WS_Resposta_geratokenacesso.retorno = "false" Then
            Return WS_Resposta_geratokenacesso.mensagem
        End If

        HttpContext.Current.Session("vg_link_portal_comnect") = WS_Resposta_geratokenacesso.mensagem

        Return "OK"
    End Function

End Class

Public Class Integra_NTK
    Private FlagProducao As Boolean

    Public Sub New(ByVal Producao As Boolean)
        FlagProducao = Producao
    End Sub

    Public Function Enviar_Pedido(DadosCliente As DataTable, CodProduto As Integer, NumPedido As Integer, PayReport As Boolean, InsPed As ExecutaSP) As String
        Dim Conteudo As String
        Dim Resposta() As String
        Dim obj As JObject

        Dim ID_Pessoa_Politica As Integer
        Dim ID_Pessoa_Parceiro As Integer
        Dim ID_Pessoa As Integer
        Dim ID_Endereco As Integer
        Dim ID_Contato As Integer
        Dim ID_Pedido As Integer

        Dim vlCNPJCliente As String = ""

        vlCNPJCliente = Replace(DadosCliente.Rows(0)("CLI_CNPJ"), ".", "")
        vlCNPJCliente = Replace(vlCNPJCliente, "/", "")
        vlCNPJCliente = Replace(vlCNPJCliente, "-", "")
        vlCNPJCliente = """" & vlCNPJCliente & """"

        If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
            Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/pessoaPolitica/listarporautenticacao", "elgin.integracao", "XHW0y", "{""Recursivo"":1}").Split("|")
        Else 'Caso for Consumir o WS de Homologação da NTK
            Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/pessoaPolitica/listarporautenticacao", "elgin.integracao", "uEaxB", "{""Recursivo"":1}").Split("|")
        End If

        If Resposta(0) <> "OK" Then
            Return Resposta(0)
        End If


        obj = JObject.Parse(Resposta(1))

        ID_Pessoa_Politica = CInt(obj("PessoaPoliticas")(0)("ID_Pessoa_Politica").ToString())

        Conteudo = "{" &
            """CNPJ_CPF"": " & vlCNPJCliente & "," &
            """ID_Pessoa_Politica"": " & ID_Pessoa_Politica & "," &
            """RazaoSocial_Nome"": " & """" & DadosCliente.Rows(0)("CLI_RAZAO_SOCIAL") & """" & "," &
            """NomeFantasia_Sobrenome"": " & """" & DadosCliente.Rows(0)("CLI_NOME_FANTASIA") & """" & "," &
            """InscricaoEstadual_RG"": " & """" & DadosCliente.Rows(0)("CLI_IE") & """" &
            "}"

        If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
            Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/pessoaParceiro/cadastrarPessoaCliente", "elgin.integracao", "XHW0y", Conteudo).Split("|")
        Else 'Caso for Consumir o WS de Homologação da NTK
            Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/pessoaParceiro/cadastrarPessoaCliente", "elgin.integracao", "uEaxB", Conteudo).Split("|")
        End If

        If Resposta(0) <> "OK" Then
            Return Resposta(0)
        End If

        obj = JObject.Parse(Resposta(1))

        ID_Pessoa_Parceiro = CInt(obj("PessoaParceiro")("ID_Pessoa_Parceiro").ToString())
        ID_Pessoa = CInt(obj("PessoaParceiro")("ID_Pessoa").ToString())

        Conteudo = "{" &
            """ID_Pessoa_Parceiro"": " & ID_Pessoa_Parceiro & "," &
            """Logradouro"": " & """" & DadosCliente.Rows(0)("CLI_ENDERECO") & """" & "," &
            """Numero"": " & """" & DadosCliente.Rows(0)("CLI_NUMERO") & """" & "," &
            """Cidade"": " & """" & DadosCliente.Rows(0)("CLI_CIDADE") & """" & "," &
            """Bairro"": " & """" & DadosCliente.Rows(0)("CLI_BAIRRO") & """" & "," &
            """UF"": " & """" & DadosCliente.Rows(0)("CLI_UF") & """" & "," &
            """Complemento"": " & """" & DadosCliente.Rows(0)("CLI_COMPLEMENTO") & """" & "," &
            """Observacao"": " & "null" & "," &
            """CEP"": " & """" & DadosCliente.Rows(0)("CLI_CEP") & """" & "," &
            """ID_Pais"": " & "33" &
            "}"

        If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
            Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/pessoaParceiro/cadastrarEndereco", "elgin.integracao", "XHW0y", Conteudo).Split("|")
        Else 'Caso for Consumir o WS de Homologação da NTK
            Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/pessoaParceiro/cadastrarEndereco", "elgin.integracao", "uEaxB", Conteudo).Split("|")
        End If

        If Resposta(0) <> "OK" Then
            Return Resposta(0)
        End If

        obj = JObject.Parse(Resposta(1))

        ID_Endereco = CInt(obj("Endereco")("ID_Endereco").ToString())

        Conteudo = "{" &
            """ID_Endereco"": " & ID_Endereco & "," &
            """Nome"": " & """" & DadosCliente.Rows(0)("CLI_CONTATO") & """" & "," &
            """Email"": " & """" & DadosCliente.Rows(0)("CLI_EMAIL") & """" & "," &
            """Telefone"": " & """" & DadosCliente.Rows(0)("CLI_TELEFONE") & """" & "," &
            """DDD"": " & """" & DadosCliente.Rows(0)("CLI_DDDTELEFONE") & """" & "," &
            """Celular"": " & """" & DadosCliente.Rows(0)("CLI_CELULAR") & """" & "," &
            """DDDc"": " & """" & DadosCliente.Rows(0)("CLI_DDDCELULAR") & """" & "," &
            """Observacao"": " & "null" &
            "}"

        If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
            Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/contato/inserir", "elgin.integracao", "XHW0y", Conteudo).Split("|")
        Else 'Caso for Consumir o WS de Homologação da NTK
            Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/contato/inserir", "elgin.integracao", "uEaxB", Conteudo).Split("|")
        End If

        If Resposta(0) <> "OK" Then
            Return Resposta(0)
        End If

        obj = JObject.Parse(Resposta(1))

        ID_Contato = CInt(obj("Contato")("ID_Contato").ToString())

        Dim SelAfiliacoes As New SelectSP("AC_SP_SEL_CLIENTES_AFILIACOES")
        SelAfiliacoes.addParam("@CAF_CLICODIGO", DadosCliente.Rows(0)("CLI_CODIGO"))
        SelAfiliacoes.Executa()

        If SelAfiliacoes.sDataTable.Rows.Count > 0 Then
            For K = 0 To SelAfiliacoes.sDataTable.Rows.Count - 1
                If SelAfiliacoes.sDataTable.Rows(K)("ADQ_INTEGRA_NTK") <> 0 Then 'If Incluído em 26/07/2018 - Por Claudio Shiniti: Integra com NTK, apenas as adquirentes que houverem seus códigos de integração com a NTK
                    Dim adqIntegraNTK As Integer = SelAfiliacoes.sDataTable.Rows(K)("ADQ_INTEGRA_NTK")

                    If NumPedido = 4672 Or NumPedido = 4673 Then
                        If adqIntegraNTK = 5 Then
                            adqIntegraNTK = 257
                        ElseIf adqIntegraNTK = 6 Then
                            adqIntegraNTK = 258
                        End If
                    End If

                    'Consulta no WS da NTK antes para ver se a afiliação já existe para esse cliente, caso sim, apenas atualiza, caso não, insere como novo
                    Conteudo = "{" &
                    """ID_Pessoa"": " & ID_Pessoa & "," &
                    """ID_Rede"": " & adqIntegraNTK &
                    "}"

                    If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
                        Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/afiliacao/listarPorFiltros", "elgin.integracao", "XHW0y", Conteudo).Split("|")
                    Else 'Caso for Consumir o WS de Homologação da NTK
                        Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/afiliacao/listarPorFiltros", "elgin.integracao", "uEaxB", Conteudo).Split("|")
                    End If

                    If Resposta(0) <> "OK" Then
                        Return Resposta(0)
                    End If

                    obj = JObject.Parse(Resposta(1))

                    If obj("Afiliacoes").ToString = "" Then 'Caso não existir, insere
                        Conteudo = "{" &
                            """ID_Rede"": " & adqIntegraNTK & "," &
                            """ID_Pessoa"": " & ID_Pessoa & "," &
                            """Numero"": " & """" & SelAfiliacoes.sDataTable.Rows(K)("CAF_NUMERO_ESTABELECIMENTO") & """" &
                            "}"

                        If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
                            Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/afiliacao/inserir", "elgin.integracao", "XHW0y", Conteudo).Split("|")
                        Else 'Caso for Consumir o WS de Homologação da NTK
                            Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/afiliacao/inserir", "elgin.integracao", "uEaxB", Conteudo).Split("|")
                        End If

                        If Resposta(0) <> "OK" Then
                            Return Resposta(0)
                        End If
                    Else 'Caso existir, consome o método para editar e apenas atualizar
                        Conteudo = "{" &
                            """ID_Afiliacao"":" & obj("Afiliacoes")(0)("ID_Afiliacao").ToString() & "," &
                            """ID_Rede"": " & adqIntegraNTK & "," &
                            """ID_Pessoa"": " & ID_Pessoa & "," &
                            """Numero"": " & """" & SelAfiliacoes.sDataTable.Rows(K)("CAF_NUMERO_ESTABELECIMENTO") & """" &
                            "}"

                        If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
                            Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/afiliacao/editar", "elgin.integracao", "XHW0y", Conteudo).Split("|")
                        Else 'Caso for Consumir o WS de Homologação da NTK
                            Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/afiliacao/editar", "elgin.integracao", "uEaxB", Conteudo).Split("|")
                        End If

                        If Resposta(0) <> "OK" And Resposta(0).ToUpper().IndexOf("NÃO É POSSIVEL ALTERAR AFILIAÇÃO") = -1 Then
                            Return Resposta(0)
                        End If
                    End If
                End If
            Next
        End If

        Dim SelProdutosNTK As New SelectSP("AC_SP_SEL_PRODUTOS_INTEGRA_NTK")

        SelProdutosNTK.addParam("@NTK_PDTCODIGO", CodProduto)

        SelProdutosNTK.Executa()

        If SelProdutosNTK.sDataTable.Rows.Count = 0 Then
            Return "Erro WebService NTK - ID_PoliticaProdutoComplementoPreco não cadastrados na base para esse produto."
        End If

        Conteudo = "{" &
            """ID_Pessoa_Parceiro"": " & ID_Pessoa_Parceiro & "," &
            """ID_Pessoa_Politica"": " & ID_Pessoa_Politica & "," &
            """ID_Endereco"": " & ID_Endereco & "," &
            """ID_EnderecoCobranca"": " & ID_Endereco & "," &
            """ID_Contato_Endereco"": " & ID_Contato & "," &
            """ID_Contato_EnderecoCobranca"": " & ID_Contato & "," &
            """ID_PedidoTipo"": 1," &
            """PedidoDetalhes"":[" &
            "{" & """ID_PoliticaProdutoComplementoPreco"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_SERVER") & "}," &
            "{" & """ID_PoliticaProdutoComplementoPreco"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_VPN") & "}," &
            "{" & """ID_PoliticaProdutoComplementoPreco"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_HELP") & "},"

        Dim SelCheckouts As New SelectSP("AC_SP_SEL_IP_TOTAL_CHECKOUTS", InsPed.Conexao, InsPed.Transacao)

        SelCheckouts.addParam("@PIT_CODIGO", NumPedido)

        SelCheckouts.Executa()

        If SelCheckouts.sDataTable.Rows.Count = 0 Then
            Return "Erro WebService NTK - Não existem Checkouts cadastrados para esse pedido."
        End If

        For K = 0 To SelCheckouts.sDataTable.Rows.Count - 1
            Conteudo &= "{" &
                """ID_PoliticaProdutoComplementoPreco"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_WINDOWS") & ","

            If SelCheckouts.sDataTable.Rows(K)("TIPO_CHECKOUT") = "Pin Pad Próprio" Then
                Conteudo &= """ID_PoliticaProdutoComplementoPreco_Atributo"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_PIN_PROPRIO") & "},"
            ElseIf SelCheckouts.sDataTable.Rows(K)("TIPO_CHECKOUT") = "Pin Pad Alugado Cielo" And SelCheckouts.sDataTable.Rows(K)("INT_TIPO_INTERFACE") = "USB" Then
                Conteudo &= """ID_PoliticaProdutoComplementoPreco_Atributo"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_USB_CIELO") & "},"
            ElseIf SelCheckouts.sDataTable.Rows(K)("TIPO_CHECKOUT") = "Pin Pad Alugado Cielo" And SelCheckouts.sDataTable.Rows(K)("INT_TIPO_INTERFACE") = "PORTA  SERIAL" Then
                Conteudo &= """ID_PoliticaProdutoComplementoPreco_Atributo"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_SERIAL_CIELO") & "},"
            ElseIf SelCheckouts.sDataTable.Rows(K)("TIPO_CHECKOUT") = "Pin Pad Alugado Rede" And SelCheckouts.sDataTable.Rows(K)("INT_TIPO_INTERFACE") = "USB" Then
                Conteudo &= """ID_PoliticaProdutoComplementoPreco_Atributo"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_USB_REDE") & "},"
            ElseIf SelCheckouts.sDataTable.Rows(K)("TIPO_CHECKOUT") = "Pin Pad Alugado Rede" And SelCheckouts.sDataTable.Rows(K)("INT_TIPO_INTERFACE") = "PORTA  SERIAL" Then
                Conteudo &= """ID_PoliticaProdutoComplementoPreco_Atributo"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_SERIAL_REDE") & "},"
            End If
        Next

        If PayReport Then
            Conteudo &= "{" &
                """ID_PoliticaProdutoComplementoPreco"": " & SelProdutosNTK.sDataTable.Rows(0)("NTK_PAYREPORT_LIGHT") & "}"
        Else 'Retira a última vírgula, caso não houver PayReport
            Conteudo = Mid(Conteudo, 1, Len(Conteudo) - 1)
        End If

        Conteudo &= "]" &
            "}"

        If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
            Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/pedido/inserirEnviarPedido", "elgin.integracao", "XHW0y", Conteudo).Split("|")
        Else 'Caso for Consumir o WS de Homologação da NTK
            Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/pedido/inserirEnviarPedido", "elgin.integracao", "uEaxB", Conteudo).Split("|")
        End If

        If Resposta(0) <> "OK" Then
            Return Resposta(0)
        End If

        obj = JObject.Parse(Resposta(1))

        ID_Pedido = CInt(obj("Pedido")("ID_Pedido").ToString())

        HttpContext.Current.Session("vg_Integrou_NTK") = ID_Pessoa_Parceiro.ToString() & ";" & ID_Pedido.ToString()

        Dim Upd_Cliente_NTK As New SelectSP("AC_SP_UPD_CLIENTE_NTK", InsPed.Conexao, InsPed.Transacao)
        Upd_Cliente_NTK.addParam("@CLI_CODIGO", DadosCliente.Rows(0)("CLI_CODIGO"))
        Upd_Cliente_NTK.addParam("@CLI_NTK_ID_PESSOA_PARCEIRO", ID_Pessoa_Parceiro)

        Upd_Cliente_NTK.Executa()

        Dim Upd_Pedido_NTK As New SelectSP("AC_SP_UPD_PEDIDO_NTK", InsPed.Conexao, InsPed.Transacao)
        Upd_Pedido_NTK.addParam("@PIT_CODIGO", NumPedido)
        Upd_Pedido_NTK.addParam("@PIT_PEDIDO_NTK", ID_Pedido)

        Upd_Pedido_NTK.Executa()

        Return "ok"
    End Function

    Public Function Status_Pedido(NumPedidoNTK As Integer) As String
        Dim Resposta() As String
        Dim obj As JObject
        'Dim ID_PedidoStatus As String
        'Dim K As Integer

        If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
            Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/pedido/buscarPorId", "elgin.integracao", "XHW0y", "{""ID_Pedido"": " & NumPedidoNTK & ",""Recursivo"":1}").Split("|")
        Else 'Caso for Consumir o WS de Homologação da NTK
            Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/pedido/buscarPorId", "elgin.integracao", "uEaxB", "{""ID_Pedido"": " & NumPedidoNTK & ",""Recursivo"":1}").Split("|")
        End If

        If Resposta(0) <> "OK" Then
            Return Resposta(0)
        End If

        obj = JObject.Parse(Resposta(1))

        Return obj("Pedido")("PedidoStatus")("Nome")

        'If FlagProducao Then 'Caso for Consumir o WS de Produção da NTK
        '    Resposta = Consome_Rest("http://api.ntkonline.com.br/v0.1/pedidostatus/listar", "elgin.integracao", "XHW0y", "").Split("|")
        'Else 'Caso for Consumir o WS de Homologação da NTK
        '    Resposta = Consome_Rest("http://apicert.ntkonline.com.br/v0.1/pedidostatus/listar", "elgin.integracao", "uEaxB", "").Split("|")
        'End If

        'If Resposta(0) <> "OK" Then
        '    Return Resposta(0)
        'End If

        'obj = JObject.Parse(Resposta(1))

        'For K = 0 To obj("PedidoStatus").Count - 1
        '    If ID_PedidoStatus = obj("PedidoStatus")(K)("ID_PedidoStatus").ToString() Then
        '        Return obj("PedidoStatus")(K)("Nome").ToString()
        '    End If
        'Next

        'Return ""
    End Function

End Class
