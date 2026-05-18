function CodeBlock(block)
  local lang = block.classes[1] or "text"
  local body = block.text
  return pandoc.RawBlock('latex', string.format([[\begin{minted}[breaklines,breakanywhere]{%s}
%s
\end{minted}]], lang, body))
end
