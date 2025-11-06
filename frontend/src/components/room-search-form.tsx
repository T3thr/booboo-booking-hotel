'use client';

import { useState, useEffect, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';

interface RoomSearchFormProps {
    onSearch: (params: {
        check_in_date: string;
        check_out_date: string;
        adults: number;
        children: number;
    }) => void;
    isLoading?: boolean;
}

export function RoomSearchForm({ onSearch, isLoading }: RoomSearchFormProps) {
    const today = new Date().toISOString().split('T')[0];
    
    // Empty by default - no pre-filled values
    const [checkIn, setCheckIn] = useState('');
    const [checkOut, setCheckOut] = useState('');
    const [adults, setAdults] = useState<number | ''>('');
    const [children, setChildren] = useState<number | ''>('');
    const [errors, setErrors] = useState<Record<string, string>>({});
    const [touched, setTouched] = useState<Record<string, boolean>>({});

    // Real-time validation
    useEffect(() => {
        if (Object.keys(touched).length > 0) {
            validateForm(true);
        }
    }, [checkIn, checkOut, adults, children, touched]);

    // Calculate nights dynamically
    const nights = useMemo(() => {
        if (checkIn && checkOut) {
            const start = new Date(checkIn);
            const end = new Date(checkOut);
            const diff = Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
            return diff > 0 ? diff : 0;
        }
        return 0;
    }, [checkIn, checkOut]);

    // Calculate total guests
    const totalGuests = useMemo(() => {
        const adultsNum = typeof adults === 'number' ? adults : 0;
        const childrenNum = typeof children === 'number' ? children : 0;
        return adultsNum + childrenNum;
    }, [adults, children]);

    const validateForm = (isRealTime = false) => {
        const newErrors: Record<string, string> = {};

        if (!checkIn && (!isRealTime || touched.checkIn)) {
            newErrors.checkIn = 'กรุณาเลือกวันเช็คอิน';
        } else if (checkIn && new Date(checkIn) < new Date(today)) {
            newErrors.checkIn = 'ไม่สามารถเลือกวันในอดีตได้';
        }

        if (!checkOut && (!isRealTime || touched.checkOut)) {
            newErrors.checkOut = 'กรุณาเลือกวันเช็คเอาท์';
        } else if (checkIn && checkOut && new Date(checkOut) <= new Date(checkIn)) {
            newErrors.checkOut = 'วันเช็คเอาท์ต้องหลังวันเช็คอิน';
        }

        if ((!adults || adults < 1) && (!isRealTime || touched.adults)) {
            newErrors.adults = 'ต้องมีผู้ใหญ่อย่างน้อย 1 คน';
        } else if (adults && adults > 10) {
            newErrors.adults = 'จำนวนผู้ใหญ่สูงสุด 10 คน';
        }

        if (children && (children < 0 || children > 10)) {
            newErrors.children = 'จำนวนเด็ก 0-10 คน';
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleBlur = (field: string) => {
        setTouched(prev => ({ ...prev, [field]: true }));
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        
        // Mark all fields as touched
        setTouched({
            checkIn: true,
            checkOut: true,
            adults: true,
            children: true,
        });

        if (validateForm()) {
            onSearch({
                check_in_date: checkIn,
                check_out_date: checkOut,
                adults: typeof adults === 'number' ? adults : 0,
                children: typeof children === 'number' ? children : 0,
            });
        }
    };

    const handleQuickSelect = (days: number) => {
        const start = new Date();
        start.setDate(start.getDate() + 1); // Tomorrow
        const end = new Date(start);
        end.setDate(end.getDate() + days);
        
        setCheckIn(start.toISOString().split('T')[0]);
        setCheckOut(end.toISOString().split('T')[0]);
        setTouched(prev => ({ ...prev, checkIn: true, checkOut: true }));
    };

    const handleGuestPreset = (adultsCount: number, childrenCount: number) => {
        setAdults(adultsCount);
        setChildren(childrenCount);
        setTouched(prev => ({ ...prev, adults: true, children: true }));
    };

    const isFormValid = checkIn && checkOut && adults && adults >= 1 && Object.keys(errors).length === 0;

    return (
        <Card className="p-6 mb-8 bg-gradient-to-br from-card to-card/50 backdrop-blur-sm border-2 shadow-xl">
            <form onSubmit={handleSubmit} className="space-y-6">
                {/* Quick Select Buttons */}
                <div className="flex flex-wrap gap-2 pb-4 border-b border-border/50">
                    <span className="text-sm font-medium text-muted-foreground mr-2 self-center">
                        เลือกด่วน:
                    </span>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleQuickSelect(1)}
                        className="hover:bg-primary hover:text-primary-foreground transition-all"
                    >
                        1 คืน
                    </Button>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleQuickSelect(2)}
                        className="hover:bg-primary hover:text-primary-foreground transition-all"
                    >
                        2 คืน
                    </Button>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleQuickSelect(3)}
                        className="hover:bg-primary hover:text-primary-foreground transition-all"
                    >
                        3 คืน
                    </Button>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleQuickSelect(7)}
                        className="hover:bg-primary hover:text-primary-foreground transition-all"
                    >
                        1 สัปดาห์
                    </Button>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    {/* Check-in Date */}
                    <div className="space-y-2">
                        <label htmlFor="checkIn" className="block text-sm font-semibold text-foreground">
                            <span className="flex items-center gap-2">
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                </svg>
                                วันเช็คอิน
                            </span>
                        </label>
                        <Input
                            id="checkIn"
                            type="date"
                            value={checkIn}
                            onChange={(e) => setCheckIn(e.target.value)}
                            onBlur={() => handleBlur('checkIn')}
                            min={today}
                            placeholder="เลือกวันที่"
                            className={`transition-all ${errors.checkIn ? 'border-destructive ring-2 ring-destructive/20' : 'focus:ring-2 focus:ring-primary/20'}`}
                        />
                        {errors.checkIn && touched.checkIn && (
                            <p className="text-destructive text-xs flex items-center gap-1 animate-in fade-in slide-in-from-top-1">
                                <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                                {errors.checkIn}
                            </p>
                        )}
                    </div>

                    {/* Check-out Date */}
                    <div className="space-y-2">
                        <label htmlFor="checkOut" className="block text-sm font-semibold text-foreground">
                            <span className="flex items-center gap-2">
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                </svg>
                                วันเช็คเอาท์
                                {nights > 0 && (
                                    <span className="text-xs font-normal text-primary">
                                        ({nights} คืน)
                                    </span>
                                )}
                            </span>
                        </label>
                        <Input
                            id="checkOut"
                            type="date"
                            value={checkOut}
                            onChange={(e) => setCheckOut(e.target.value)}
                            onBlur={() => handleBlur('checkOut')}
                            min={checkIn || today}
                            placeholder="เลือกวันที่"
                            className={`transition-all ${errors.checkOut ? 'border-destructive ring-2 ring-destructive/20' : 'focus:ring-2 focus:ring-primary/20'}`}
                        />
                        {errors.checkOut && touched.checkOut && (
                            <p className="text-destructive text-xs flex items-center gap-1 animate-in fade-in slide-in-from-top-1">
                                <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                                {errors.checkOut}
                            </p>
                        )}
                    </div>

                    {/* Adults */}
                    <div className="space-y-2">
                        <label htmlFor="adults" className="block text-sm font-semibold text-foreground">
                            <span className="flex items-center gap-2">
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                </svg>
                                ผู้ใหญ่
                            </span>
                        </label>
                        <div className="flex gap-2">
                            <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={() => setAdults(prev => Math.max(0, (typeof prev === 'number' ? prev : 0) - 1))}
                                disabled={!adults || adults <= 0}
                                className="px-3"
                            >
                                −
                            </Button>
                            <Input
                                id="adults"
                                type="number"
                                value={adults}
                                onChange={(e) => setAdults(e.target.value === '' ? '' : parseInt(e.target.value))}
                                onBlur={() => handleBlur('adults')}
                                min={0}
                                max={10}
                                placeholder="0"
                                className={`text-center transition-all ${errors.adults ? 'border-destructive ring-2 ring-destructive/20' : 'focus:ring-2 focus:ring-primary/20'}`}
                            />
                            <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={() => setAdults(prev => Math.min(10, (typeof prev === 'number' ? prev : 0) + 1))}
                                disabled={typeof adults === 'number' && adults >= 10}
                                className="px-3"
                            >
                                +
                            </Button>
                        </div>
                        {errors.adults && touched.adults && (
                            <p className="text-destructive text-xs flex items-center gap-1 animate-in fade-in slide-in-from-top-1">
                                <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                                {errors.adults}
                            </p>
                        )}
                    </div>

                    {/* Children */}
                    <div className="space-y-2">
                        <label htmlFor="children" className="block text-sm font-semibold text-foreground">
                            <span className="flex items-center gap-2">
                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                เด็ก
                            </span>
                        </label>
                        <div className="flex gap-2">
                            <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={() => setChildren(prev => Math.max(0, (typeof prev === 'number' ? prev : 0) - 1))}
                                disabled={!children || children <= 0}
                                className="px-3"
                            >
                                −
                            </Button>
                            <Input
                                id="children"
                                type="number"
                                value={children}
                                onChange={(e) => setChildren(e.target.value === '' ? '' : parseInt(e.target.value))}
                                onBlur={() => handleBlur('children')}
                                min={0}
                                max={10}
                                placeholder="0"
                                className={`text-center transition-all ${errors.children ? 'border-destructive ring-2 ring-destructive/20' : 'focus:ring-2 focus:ring-primary/20'}`}
                            />
                            <Button
                                type="button"
                                variant="outline"
                                size="sm"
                                onClick={() => setChildren(prev => Math.min(10, (typeof prev === 'number' ? prev : 0) + 1))}
                                disabled={typeof children === 'number' && children >= 10}
                                className="px-3"
                            >
                                +
                            </Button>
                        </div>
                        {errors.children && touched.children && (
                            <p className="text-destructive text-xs flex items-center gap-1 animate-in fade-in slide-in-from-top-1">
                                <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                                </svg>
                                {errors.children}
                            </p>
                        )}
                    </div>
                </div>

                {/* Guest Presets */}
                <div className="flex flex-wrap gap-2 pt-2 border-t border-border/50">
                    <span className="text-sm font-medium text-muted-foreground mr-2 self-center">
                        จำนวนผู้เข้าพัก:
                    </span>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleGuestPreset(1, 0)}
                        className="hover:bg-primary hover:text-primary-foreground transition-all"
                    >
                        1 คน
                    </Button>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleGuestPreset(2, 0)}
                        className="hover:bg-primary hover:text-primary-foreground transition-all"
                    >
                        2 คน
                    </Button>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleGuestPreset(2, 2)}
                        className="hover:bg-primary hover:text-primary-foreground transition-all"
                    >
                        ครอบครัว (2+2)
                    </Button>
                    <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => handleGuestPreset(4, 0)}
                        className="hover:bg-primary hover:text-primary-foreground transition-all"
                    >
                        กลุ่ม 4 คน
                    </Button>
                </div>

                {/* Summary & Submit */}
                <div className="flex flex-col sm:flex-row justify-between items-center gap-4 pt-4 border-t border-border/50">
                    <div className="text-sm text-muted-foreground">
                        {totalGuests > 0 && nights > 0 && (
                            <span className="flex items-center gap-2 animate-in fade-in slide-in-from-left-2">
                                <svg className="w-4 h-4 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                </svg>
                                <strong className="text-foreground">{totalGuests} ท่าน</strong> พัก <strong className="text-foreground">{nights} คืน</strong>
                            </span>
                        )}
                    </div>
                    <Button 
                        type="submit" 
                        disabled={isLoading || !isFormValid} 
                        className="px-8 py-6 text-base font-semibold shadow-lg hover:shadow-xl transition-all disabled:opacity-50"
                        size="lg"
                    >
                        {isLoading ? (
                            <span className="flex items-center gap-2">
                                <svg className="animate-spin h-5 w-5" fill="none" viewBox="0 0 24 24">
                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                </svg>
                                กำลังค้นหา...
                            </span>
                        ) : (
                            <span className="flex items-center gap-2">
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                </svg>
                                ค้นหาห้องพัก
                            </span>
                        )}
                    </Button>
                </div>
            </form>
        </Card>
    );
}
