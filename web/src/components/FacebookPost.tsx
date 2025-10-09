import React, { forwardRef, useState } from 'react';

interface CanvasLayer {
  id: string;
  type: string;
  name: string;
  visible: boolean;
  locked: boolean;
  opacity: number;
  transform: {
    x: number;
    y: number;
    rotation: number;
    scaleX: number;
    scaleY: number;
    opacity: number;
  };
  content: {
    text?: string;
    fontSize?: number;
    fontFamily?: string;
    color?: string;
    fontWeight?: string;
    [key: string]: any;
  };
}

interface FacebookPostProps {
  className?: string;
  children?: React.ReactNode;
  layers?: CanvasLayer[];
  onAddText?: () => void;
  onAddRect?: () => void;
  onAddCircle?: () => void;
  onUpdatePostText?: (newText: string) => void;
}

const FacebookPost = forwardRef<HTMLDivElement, FacebookPostProps>(
  ({ className = '', children, layers = [], onAddText, onAddRect, onAddCircle, onUpdatePostText }, ref) => {
    // Find post text layer
    const postTextLayer = layers.find(layer => layer.type === 'post_text');
    const postText = postTextLayer?.content?.text || 'Add your post text here...';
    
    // Editing state
    const [isEditing, setIsEditing] = useState(false);
    const [editText, setEditText] = useState(postText);
    
    // Handle editing
    const handleStartEdit = () => {
      setIsEditing(true);
      setEditText(postText);
    };
    
    const handleSaveEdit = () => {
      if (onUpdatePostText) {
        onUpdatePostText(editText);
      }
      setIsEditing(false);
    };
    
    const handleCancelEdit = () => {
      setEditText(postText);
      setIsEditing(false);
    };
    
    const handleKeyDown = (e: React.KeyboardEvent) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSaveEdit();
      } else if (e.key === 'Escape') {
        handleCancelEdit();
      }
    };
    return (
      <div className={`flex flex-col h-full max-h-screen overflow-hidden ${className}`} style={{ backgroundColor: '#f0f2f5' }}>
        {/* Canvas - Fills remaining mobile viewport with proper Facebook post */}
        <div className="flex-1 w-full overflow-hidden">
          <div className="h-full w-full relative bg-white" ref={ref}>
            {/* Facebook Post Content - Mobile First, Contained Within Phone */}
            <div className="max-w-full mx-auto bg-white shadow-sm border border-gray-200 rounded-none h-full overflow-y-auto">
              {/* Post Header */}
              <div className="flex-shrink-0 w-full bg-white border-b border-gray-200 px-3 py-2">
                <div className="flex items-center space-x-3">
                  <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center">
                    <span className="text-white text-sm font-medium">JD</span>
                  </div>
                  <div>
                    <div className="text-sm font-semibold text-gray-900">John Doe</div>
                    <div className="text-xs text-gray-500">2 hrs · 🌍</div>
                  </div>
                </div>
              </div>

              {/* Post Content */}
              <div className="px-3 py-2">
                {/* Canvas Area - Where you can design */}
                <div className="w-full rounded-lg overflow-hidden mb-5" style={{ aspectRatio: '16/10' }}>
                  {children}
                </div>
                {/* Post Text - Editable */}
                {isEditing ? (
                  <div className="mb-3">
                    <textarea
                      value={editText}
                      onChange={(e) => setEditText(e.target.value)}
                      onKeyDown={handleKeyDown}
                      onBlur={handleSaveEdit}
                      className="w-full text-gray-900 text-sm leading-relaxed bg-gray-50 border border-gray-200 rounded-lg p-2 resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      rows={3}
                      autoFocus
                      placeholder="What's on your mind?"
                    />
                    <div className="flex gap-2 mt-2">
                      <button
                        onClick={handleSaveEdit}
                        className="px-3 py-1 bg-blue-600 text-white text-xs rounded hover:bg-blue-700 transition-colors"
                      >
                        Save
                      </button>
                      <button
                        onClick={handleCancelEdit}
                        className="px-3 py-1 bg-gray-300 text-gray-700 text-xs rounded hover:bg-gray-400 transition-colors"
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                ) : (
                  <p 
                    className="text-gray-900 text-sm leading-relaxed mb-3 cursor-pointer hover:bg-gray-50 rounded p-1 transition-colors"
                    onClick={handleStartEdit}
                    title="Click to edit post text"
                  >
                    {postText}
                  </p>
                )}
              </div>

              {/* Engagement Stats */}
              <div className="px-3 py-2 border-t border-gray-100">
                <div className="flex items-center justify-between text-xs text-gray-500">
                  <div className="flex items-center">
                    <div className="flex items-center -space-x-1">
                      <div className="w-4 h-4 bg-blue-500 rounded-full flex items-center justify-center">
                        <span className="text-white text-xs">👍</span>
                      </div>
                      <div className="w-4 h-4 bg-red-500 rounded-full flex items-center justify-center -ml-1">
                        <span className="text-white text-xs">❤️</span>
                      </div>
                    </div>
                    <span className="text-gray-600 text-xs ml-1">24</span>
                  </div>
                  <div className="text-gray-500 text-xs">
                    <span>3 comments</span>
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="border-t border-gray-200 px-1 py-1">
                <div className="flex">
                  <button className="flex-1 flex items-center justify-center py-2 text-gray-600 hover:bg-gray-50 transition-colors">
                    <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V8a2 2 0 00-2-2H4.5c-.9 0-1.5.6-1.5 1.5v1c0 .9.6 1.5 1.5 1.5H7m7-10v2m0 0V8c0-1.1-.9-2-2-2H7m7 0h3"/>
                    </svg>
                    <span className="text-xs font-medium">Like</span>
                  </button>
                  <button className="flex-1 flex items-center justify-center py-2 text-gray-600 hover:bg-gray-50 transition-colors">
                    <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                    </svg>
                    <span className="text-xs font-medium">Comment</span>
                  </button>
                  <button className="flex-1 flex items-center justify-center py-2 text-gray-600 hover:bg-gray-50 transition-colors">
                    <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z"/>
                    </svg>
                    <span className="text-xs font-medium">Share</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Mobile Bottom Toolbar */}
        <div className="flex-shrink-0 w-full bg-white border-t border-gray-200 px-4 py-3 safe-area-inset-bottom">
          <div className="flex justify-center space-x-4">
            <button
              onClick={onAddText}
              className="flex-1 max-w-20 px-3 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
            >
              Text
            </button>
            <button
              onClick={onAddRect}
              className="flex-1 max-w-20 px-3 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 transition-colors"
            >
              Rect
            </button>
            <button
              onClick={onAddCircle}
              className="flex-1 max-w-20 px-3 py-2 bg-purple-600 text-white rounded-lg text-sm font-medium hover:bg-purple-700 transition-colors"
            >
              Circle
            </button>
          </div>
        </div>
      </div>
    );
  }
);

FacebookPost.displayName = 'FacebookPost';

export default FacebookPost;